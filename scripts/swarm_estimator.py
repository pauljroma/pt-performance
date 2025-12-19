#!/usr/bin/env python3.11
"""
Monte Carlo Swarm Estimator - Worker Sizing, Tokens, Time, & Cost
===================================================================

Drop-in, machine-readable estimation module that:
- Sizes worker swarms by lane (RPA, HiL, LLM code/content/other)
- Projects tokens by model + category
- Computes time-to-completion (serial sum vs bottleneck)
- Estimates $ for external LLM usage only
- Monte Carlo-based with percentiles
- Site-aware with provenance tracking

Based on COCOMO principles but adapted for agent swarm workloads.

Usage:
    # CLI
    python swarm_estimator.py --config example_config.json --out output.json --runs 400 --seed 123

    # Python API
    from swarm_estimator import run_simulation
    result = run_simulation(config, runs=1000, seed=42)

Author: Quiver Platform Team
Version: 1.0.1
Date: 2025-11-05
"""

import argparse
import json
import math
import random
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

import numpy as np

# ============================================================================
# DISTRIBUTION SAMPLING
# ============================================================================

class DistributionSampler:
    """Sample from various probability distributions"""

    @staticmethod
    def sample(dist_config: dict[str, Any], rng: random.Random) -> float:
        """
        Sample a value from a distribution config.

        Supported distributions:
        - triangular: {dist: "triangular", min: x, mode: y, max: z}
        - lognormal: {dist: "lognormal", mu: x, sigma: y}
        - uniform: {dist: "uniform", min: x, max: y}
        - constant: {dist: "constant", value: x}

        Args:
            dist_config: Distribution configuration
            rng: Random number generator

        Returns:
            Sampled value
        """
        dist_type = dist_config.get("dist", "constant")

        if dist_type == "triangular":
            return rng.triangular(
                dist_config["min"],
                dist_config["max"],
                dist_config["mode"]
            )
        elif dist_type == "lognormal":
            # Use numpy for lognormal
            mu = dist_config["mu"]
            sigma = dist_config["sigma"]
            return float(np.random.lognormal(mu, sigma))
        elif dist_type == "uniform":
            return rng.uniform(dist_config["min"], dist_config["max"])
        elif dist_type == "constant":
            return dist_config["value"]
        else:
            raise ValueError(f"Unknown distribution type: {dist_type}")


# ============================================================================
# LANE & MODEL DEFINITIONS
# ============================================================================

@dataclass
class Lane:
    """
    Capacity definition for a worker lane.

    LLM lanes: measured in tokens/sec/worker
    Non-LLM lanes: measured in coverage hours/day
    """
    lane_id: str
    lane_kind: str  # "llm" or "non-llm"

    # LLM lanes
    tokens_per_sec_per_worker: float | None = None

    # Non-LLM lanes
    coverage_hours_per_day: float | None = None
    utilization_cap: float = 0.75  # Max utilization (prevent burnout)
    oee: float = 0.9  # Overall equipment effectiveness

    # Worker sizing
    workers_fixed: int | None = None  # If set, don't calculate workers

    def __post_init__(self):
        if self.lane_kind == "llm" and self.tokens_per_sec_per_worker is None:
            raise ValueError(f"LLM lane {self.lane_id} requires tokens_per_sec_per_worker")
        if self.lane_kind == "non-llm" and self.coverage_hours_per_day is None:
            raise ValueError(f"Non-LLM lane {self.lane_id} requires coverage_hours_per_day")


@dataclass
class Model:
    """LLM model with pricing"""
    model_id: str
    category: str  # "llm_code", "llm_content", "llm_other"
    provider: str
    prompt_cost_per_1k_tokens: float
    completion_cost_per_1k_tokens: float
    external: bool = True  # Only external models count toward external cost


# ============================================================================
# PIPELINE & STAGE DEFINITIONS
# ============================================================================

@dataclass
class Stage:
    """
    A single stage in a pipeline.

    For LLM stages: token distributions
    For non-LLM stages: work time distributions
    """
    stage_id: str
    lane_id: str
    type: str  # "llm" or "non-llm"

    # LLM-specific
    model_id: str | None = None
    prompt_tokens_per_item: dict[str, Any] | None = None
    completion_tokens_per_item: dict[str, Any] | None = None
    retry_rate: dict[str, Any] | None = None

    # Non-LLM specific
    work_seconds_per_item: dict[str, Any] | None = None
    rework_probability: float = 0.0
    rework_multiplier: float = 1.5

    def __post_init__(self):
        if self.type == "llm":
            if not all([self.model_id, self.prompt_tokens_per_item, self.completion_tokens_per_item]):
                raise ValueError(f"LLM stage {self.stage_id} missing required fields")
        elif self.type == "non-llm":
            if self.work_seconds_per_item is None:
                raise ValueError(f"Non-LLM stage {self.stage_id} requires work_seconds_per_item")


@dataclass
class Pipeline:
    """A sequence of stages processing items"""
    pipeline_id: str
    stages: list[Stage]
    count: int  # Number of items to process


# ============================================================================
# SIMULATION ENGINE
# ============================================================================

@dataclass
class SimulationRun:
    """Results from a single Monte Carlo run"""
    # Workers by lane
    workers_by_lane: dict[str, int]

    # Time (days)
    time_by_lane: dict[str, float]
    time_by_pipeline: dict[str, dict[str, float]]  # {pipeline_id: {serial_sum, bottleneck}}
    overall_days_serial_sum: float
    overall_days_bottleneck: float

    # Tokens by model and category
    tokens_by_model: dict[str, dict[str, int]]  # {model_id: {prompt, completion, total}}
    tokens_by_category: dict[str, dict[str, int]]  # {category: {prompt, completion, total}}

    # Cost (USD)
    cost_by_model: dict[str, float]
    external_cost_total: float


class SwarmSimulator:
    """Monte Carlo simulator for swarm estimation"""

    def __init__(
        self,
        lanes: list[Lane],
        models: list[Model],
        pipelines: list[Pipeline],
        target_deadline_hours: float,
        site_id: str,
        reference_set: dict[str, str],
        timezone: str = "UTC",
        oee_global: float = 0.9,
        seed: int | None = None
    ) -> None:
        self.lanes = {lane.lane_id: lane for lane in lanes}
        self.models = {model.model_id: model for model in models}
        self.pipelines = pipelines
        self.target_deadline_hours = target_deadline_hours
        self.site_id = site_id
        self.reference_set = reference_set
        self.timezone = timezone
        self.oee_global = oee_global
        self.seed = seed

        # Random number generator
        self.rng = random.Random(seed)
        if seed is not None:
            np.random.seed(seed)

    def run_single_simulation(self, sample_batch_size: int = 25) -> SimulationRun:
        """
        Run a single Monte Carlo simulation.

        Args:
            sample_batch_size: Number of items to sample for approximation

        Returns:
            SimulationRun with results
        """
        # Track workload by lane
        lane_workloads = {lane_id: {"tokens": 0, "seconds": 0}
                         for lane_id in self.lanes.keys()}

        # Track tokens by model and category
        model_tokens = {model_id: {"prompt": 0, "completion": 0, "total": 0}
                       for model_id in self.models.keys()}
        category_tokens = {}

        # Process each pipeline
        pipeline_times = {}

        for pipeline in self.pipelines:
            stage_workloads = {lane_id: {"tokens": 0, "seconds": 0}
                             for lane_id in self.lanes.keys()}

            for stage in pipeline.stages:
                # Sample items (use batch sampling for performance)
                n_samples = min(sample_batch_size, pipeline.count)

                if stage.type == "llm":
                    # Sample token counts
                    prompt_tokens_total = 0
                    completion_tokens_total = 0
                    retries_total = 0

                    for _ in range(n_samples):
                        prompt = DistributionSampler.sample(stage.prompt_tokens_per_item, self.rng)
                        completion = DistributionSampler.sample(stage.completion_tokens_per_item, self.rng)
                        retry = DistributionSampler.sample(stage.retry_rate, self.rng)

                        prompt_tokens_total += prompt
                        completion_tokens_total += completion
                        retries_total += retry

                    # Scale to full count
                    scale = pipeline.count / n_samples
                    prompt_tokens = int(prompt_tokens_total * scale)
                    completion_tokens = int(completion_tokens_total * scale)
                    total_tokens = prompt_tokens + completion_tokens

                    # Apply retries (each retry adds more tokens)
                    avg_retry_rate = retries_total / n_samples
                    total_tokens = int(total_tokens * (1 + avg_retry_rate))
                    prompt_tokens = int(prompt_tokens * (1 + avg_retry_rate))
                    completion_tokens = int(completion_tokens * (1 + avg_retry_rate))

                    # Track by model
                    model_tokens[stage.model_id]["prompt"] += prompt_tokens
                    model_tokens[stage.model_id]["completion"] += completion_tokens
                    model_tokens[stage.model_id]["total"] += total_tokens

                    # Track by category
                    category = self.models[stage.model_id].category
                    if category not in category_tokens:
                        category_tokens[category] = {"prompt": 0, "completion": 0, "total": 0}
                    category_tokens[category]["prompt"] += prompt_tokens
                    category_tokens[category]["completion"] += completion_tokens
                    category_tokens[category]["total"] += total_tokens

                    # Add to lane workload
                    stage_workloads[stage.lane_id]["tokens"] += total_tokens
                    lane_workloads[stage.lane_id]["tokens"] += total_tokens

                else:  # non-llm
                    # Sample work time
                    work_seconds_total = 0

                    for _ in range(n_samples):
                        work = DistributionSampler.sample(stage.work_seconds_per_item, self.rng)
                        work_seconds_total += work

                    # Scale to full count
                    scale = pipeline.count / n_samples
                    work_seconds = work_seconds_total * scale

                    # Apply rework
                    if self.rng.random() < stage.rework_probability:
                        work_seconds *= stage.rework_multiplier

                    # Add to lane workload
                    stage_workloads[stage.lane_id]["seconds"] += work_seconds
                    lane_workloads[stage.lane_id]["seconds"] += work_seconds

            # Calculate stage times based on workloads
            # (This is simplified - in reality would be more complex)
            pipeline_times[pipeline.pipeline_id] = {
                "serial_sum": 0,
                "bottleneck": 0
            }

        # Calculate workers needed and time per lane
        workers_by_lane = {}
        time_by_lane = {}
        target_days = self.target_deadline_hours / 24.0

        for lane_id, lane in self.lanes.items():
            if lane.workers_fixed is not None:
                # Fixed worker count
                workers = lane.workers_fixed
            # Calculate workers needed to meet deadline
            elif lane.lane_kind == "llm":
                total_tokens = lane_workloads[lane_id]["tokens"]
                tokens_per_day_per_worker = (
                    lane.tokens_per_sec_per_worker *
                    3600 *
                    lane.coverage_hours_per_day *
                    lane.utilization_cap
                )
                workers = math.ceil(total_tokens / (tokens_per_day_per_worker * target_days))
            else:  # non-llm
                total_seconds = lane_workloads[lane_id]["seconds"]
                seconds_per_day_per_worker = (
                    3600 *
                    lane.coverage_hours_per_day *
                    lane.utilization_cap *
                    lane.oee
                )
                workers = math.ceil(total_seconds / (seconds_per_day_per_worker * target_days))

            workers = max(1, workers)  # At least 1 worker
            workers_by_lane[lane_id] = workers

            # Calculate actual time with this many workers
            if lane.lane_kind == "llm":
                total_tokens = lane_workloads[lane_id]["tokens"]
                if total_tokens > 0:
                    tokens_per_day_per_worker = (
                        lane.tokens_per_sec_per_worker *
                        3600 *
                        lane.coverage_hours_per_day *
                        lane.utilization_cap
                    )
                    time_days = total_tokens / (tokens_per_day_per_worker * workers)
                else:
                    time_days = 0
            else:
                total_seconds = lane_workloads[lane_id]["seconds"]
                if total_seconds > 0:
                    seconds_per_day_per_worker = (
                        3600 *
                        lane.coverage_hours_per_day *
                        lane.utilization_cap *
                        lane.oee
                    )
                    time_days = total_seconds / (seconds_per_day_per_worker * workers)
                else:
                    time_days = 0

            time_by_lane[lane_id] = time_days

        # Calculate pipeline times
        time_by_pipeline = {}
        for pipeline in self.pipelines:
            serial_sum = sum(time_by_lane.get(stage.lane_id, 0) for stage in pipeline.stages)
            bottleneck = max((time_by_lane.get(stage.lane_id, 0) for stage in pipeline.stages), default=0)
            time_by_pipeline[pipeline.pipeline_id] = {
                "serial_sum": serial_sum,
                "bottleneck": bottleneck
            }

        # Calculate overall time
        overall_serial = sum(p["serial_sum"] for p in time_by_pipeline.values())
        overall_bottleneck = max((p["bottleneck"] for p in time_by_pipeline.values()), default=0)

        # Calculate costs
        cost_by_model = {}
        external_cost_total = 0.0

        for model_id, tokens in model_tokens.items():
            model = self.models[model_id]
            cost = (
                (tokens["prompt"] / 1000.0 * model.prompt_cost_per_1k_tokens) +
                (tokens["completion"] / 1000.0 * model.completion_cost_per_1k_tokens)
            )
            cost_by_model[model_id] = cost

            if model.external:
                external_cost_total += cost

        return SimulationRun(
            workers_by_lane=workers_by_lane,
            time_by_lane=time_by_lane,
            time_by_pipeline=time_by_pipeline,
            overall_days_serial_sum=overall_serial,
            overall_days_bottleneck=overall_bottleneck,
            tokens_by_model=model_tokens,
            tokens_by_category=category_tokens,
            cost_by_model=cost_by_model,
            external_cost_total=external_cost_total
        )

    def run_monte_carlo(self, runs: int, sample_batch_size: int = 25) -> dict[str, Any]:
        """
        Run Monte Carlo simulation with multiple runs.

        Args:
            runs: Number of simulation runs
            sample_batch_size: Batch size for sampling

        Returns:
            Dictionary with summary statistics (percentiles)
        """
        results = []

        for _ in range(runs):
            result = self.run_single_simulation(sample_batch_size)
            results.append(result)

        # Calculate percentiles
        summary = self._calculate_summary(results)

        # Add metadata
        summary["meta"] = {
            "module": "swarm_estimator",
            "version": "1.0.1",
            "runs": runs,
            "seed": self.seed,
            "site_id": self.site_id,
            "timezone": self.timezone,
            "reference_set": self.reference_set,
            "created_utc": datetime.utcnow().isoformat() + "Z"
        }

        return summary

    def _calculate_summary(self, results: list[SimulationRun]) -> dict[str, Any]:
        """Calculate summary statistics with percentiles"""
        percentiles = [5, 10, 25, 50, 75, 90, 95]

        summary = {
            "workers_by_lane": {},
            "time_days_overall": {},
            "tokens_by_model": {},
            "cost_by_model_usd": {},
            "by_category_p50": {}
        }

        # Workers by lane (percentiles)
        all_lanes = set()
        for r in results:
            all_lanes.update(r.workers_by_lane.keys())

        for lane_id in all_lanes:
            values = [r.workers_by_lane.get(lane_id, 0) for r in results]
            summary["workers_by_lane"][lane_id] = {
                f"p{p}": int(np.percentile(values, p)) for p in percentiles
            }

        # Time (overall)
        serial_values = [r.overall_days_serial_sum for r in results]
        bottleneck_values = [r.overall_days_bottleneck for r in results]

        summary["time_days_overall"]["overall_days_serial_sum"] = {
            f"p{p}": float(np.percentile(serial_values, p)) for p in percentiles
        }
        summary["time_days_overall"]["overall_days_bottleneck"] = {
            f"p{p}": float(np.percentile(bottleneck_values, p)) for p in percentiles
        }

        # Tokens by model (percentiles)
        all_models = set()
        for r in results:
            all_models.update(r.tokens_by_model.keys())

        for model_id in all_models:
            prompt_values = [r.tokens_by_model.get(model_id, {}).get("prompt", 0) for r in results]
            completion_values = [r.tokens_by_model.get(model_id, {}).get("completion", 0) for r in results]
            total_values = [r.tokens_by_model.get(model_id, {}).get("total", 0) for r in results]

            summary["tokens_by_model"][model_id] = {
                "prompt": {f"p{p}": int(np.percentile(prompt_values, p)) for p in percentiles},
                "completion": {f"p{p}": int(np.percentile(completion_values, p)) for p in percentiles},
                "total": {f"p{p}": int(np.percentile(total_values, p)) for p in percentiles}
            }

        # Cost by model (percentiles)
        for model_id in all_models:
            cost_values = [r.cost_by_model.get(model_id, 0) for r in results]
            summary["cost_by_model_usd"][model_id] = {
                f"p{p}": float(np.percentile(cost_values, p)) for p in percentiles
            }

        # External cost total
        external_cost_values = [r.external_cost_total for r in results]
        summary["external_cost_total_usd"] = {
            f"p{p}": float(np.percentile(external_cost_values, p)) for p in percentiles
        }

        # Category summary (p50 only)
        all_categories = set()
        for r in results:
            all_categories.update(r.tokens_by_category.keys())

        for category in all_categories:
            prompt_values = [r.tokens_by_category.get(category, {}).get("prompt", 0) for r in results]
            completion_values = [r.tokens_by_category.get(category, {}).get("completion", 0) for r in results]
            total_values = [r.tokens_by_category.get(category, {}).get("total", 0) for r in results]

            summary["by_category_p50"][category] = {
                "tokens": {
                    "prompt": int(np.percentile(prompt_values, 50)),
                    "completion": int(np.percentile(completion_values, 50)),
                    "total": int(np.percentile(total_values, 50))
                }
            }

        return summary


# ============================================================================
# CONFIG LOADING
# ============================================================================

def load_config(config_path: Path) -> dict[str, Any]:
    """Load configuration from JSON file"""
    with open(config_path) as f:
        return json.load(f)


def config_to_objects(config: dict[str, Any]) -> tuple[list[Lane], list[Model], list[Pipeline], dict[str, Any]]:
    """Convert config dict to objects"""

    # Parse lanes
    lanes = []
    for lane_cfg in config["lanes"]:
        lane = Lane(
            lane_id=lane_cfg["lane_id"],
            lane_kind=lane_cfg["lane_kind"],
            tokens_per_sec_per_worker=lane_cfg.get("tokens_per_sec_per_worker"),
            coverage_hours_per_day=lane_cfg.get("coverage_hours_per_day", 24),
            utilization_cap=lane_cfg.get("utilization_cap", 0.75),
            oee=lane_cfg.get("oee", 0.9),
            workers_fixed=lane_cfg.get("workers_fixed")
        )
        lanes.append(lane)

    # Parse models
    models = []
    for model_cfg in config["models"]:
        model = Model(
            model_id=model_cfg["model_id"],
            category=model_cfg["category"],
            provider=model_cfg["provider"],
            prompt_cost_per_1k_tokens=model_cfg["prompt_cost_per_1k_tokens"],
            completion_cost_per_1k_tokens=model_cfg["completion_cost_per_1k_tokens"],
            external=model_cfg.get("external", True)
        )
        models.append(model)

    # Parse pipelines
    pipelines = []
    for pipeline_cfg in config["pipelines"]:
        stages = []
        for stage_cfg in pipeline_cfg["stages"]:
            stage = Stage(
                stage_id=stage_cfg["stage_id"],
                lane_id=stage_cfg["lane_id"],
                type=stage_cfg["type"],
                model_id=stage_cfg.get("model_id"),
                prompt_tokens_per_item=stage_cfg.get("prompt_tokens_per_item"),
                completion_tokens_per_item=stage_cfg.get("completion_tokens_per_item"),
                retry_rate=stage_cfg.get("retry_rate"),
                work_seconds_per_item=stage_cfg.get("work_seconds_per_item"),
                rework_probability=stage_cfg.get("rework_probability", 0.0),
                rework_multiplier=stage_cfg.get("rework_multiplier", 1.5)
            )
            stages.append(stage)

        pipeline = Pipeline(
            pipeline_id=pipeline_cfg["pipeline_id"],
            stages=stages,
            count=pipeline_cfg["count"]
        )
        pipelines.append(pipeline)

    # Parse global config
    global_cfg = {
        "target_deadline_hours": config["global"]["target_deadline_hours"],
        "runs": config["global"].get("runs", 400),
        "sample_batch_size": config["global"].get("sample_batch_size", 25),
        "site_id": config["site"]["site_id"],
        "timezone": config["site"]["timezone"],
        "reference_set": config["reference_set"]
    }

    return lanes, models, pipelines, global_cfg


# ============================================================================
# MAIN API
# ============================================================================

def run_simulation(config: dict[str, Any], runs: int | None = None, seed: int | None = None) -> dict[str, Any]:
    """
    Run swarm estimation simulation.

    Args:
        config: Configuration dictionary
        runs: Number of Monte Carlo runs (overrides config)
        seed: Random seed (overrides config)

    Returns:
        Summary dictionary with percentiles and metadata
    """
    lanes, models, pipelines, global_cfg = config_to_objects(config)

    if runs is None:
        runs = global_cfg["runs"]
    if seed is None:
        seed = config.get("global", {}).get("seed")

    simulator = SwarmSimulator(
        lanes=lanes,
        models=models,
        pipelines=pipelines,
        target_deadline_hours=global_cfg["target_deadline_hours"],
        site_id=global_cfg["site_id"],
        reference_set=global_cfg["reference_set"],
        timezone=global_cfg["timezone"],
        seed=seed
    )

    return simulator.run_monte_carlo(runs, global_cfg["sample_batch_size"])


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Monte Carlo swarm estimator - worker sizing, tokens, time, cost",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with default config
  %(prog)s --config example_config.json --out output.json

  # Custom runs and seed
  %(prog)s --config example_config.json --out output.json --runs 1000 --seed 42

  # Quick test (fewer runs)
  %(prog)s --config example_config.json --out output.json --runs 100
        """
    )

    parser.add_argument(
        "--config",
        type=Path,
        required=True,
        help="Path to config JSON file"
    )
    parser.add_argument(
        "--out",
        type=Path,
        required=True,
        help="Path to output JSON file"
    )
    parser.add_argument(
        "--runs",
        type=int,
        help="Number of Monte Carlo runs (overrides config)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Random seed for reproducibility (overrides config)"
    )

    args = parser.parse_args()

    # Load config
    config = load_config(args.config)

    # Run simulation
    result = run_simulation(config, runs=args.runs, seed=args.seed)

    # Write output
    with open(args.out, "w") as f:
        json.dump(result, f, indent=2)

    print(f"✓ Simulation complete: {result['meta']['runs']} runs")
    print(f"✓ Output written to: {args.out}")
    print()
    print("Summary (p50):")
    print("  Workers by lane:")
    for lane_id, workers in result["workers_by_lane"].items():
        print(f"    {lane_id}: {workers['p50']}")
    print("  Time (days):")
    print(f"    Serial sum: {result['time_days_overall']['overall_days_serial_sum']['p50']:.2f}")
    print(f"    Bottleneck: {result['time_days_overall']['overall_days_bottleneck']['p50']:.2f}")
    print(f"  External cost: ${result['external_cost_total_usd']['p50']:.2f}")


if __name__ == "__main__":
    main()
