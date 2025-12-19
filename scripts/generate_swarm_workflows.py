#!/usr/bin/env python3.11
"""
Swarm Workflow Generator - Create 50+ Workflows Easily

Generate custom n8n workflows from templates:
- Different gene sets
- Different agents
- Different budgets
- Different schedules
"""

import json
import sys
from datetime import datetime
from pathlib import Path


def create_swarm_workflow(
    name: str,
    genes: list,
    agents: int = 3,
    budget: int = 50,
    schedule_hour: int = 21,  # 9pm
    optimization_mode: str = "balanced"
) -> dict:
    """Generate a swarm workflow"""

    workflow_id = f"swarm_{name.lower().replace(' ', '_')}_{datetime.now().strftime('%Y%m%d')}"

    workflow = {
        "name": f"CNS Swarm - {name}",
        "active": False,
        "nodes": [
            {
                "parameters": {},
                "id": f"{workflow_id}_execute_trigger",
                "name": "▶️ Execute Trigger",
                "type": "n8n-nodes-base.executeWorkflowTrigger",
                "typeVersion": 1,
                "position": [250, 200]
            },
            {
                "parameters": {
                    "rule": {
                        "interval": [{
                            "field": "cronExpression",
                            "expression": f"0 {schedule_hour} * * *"
                        }]
                    }
                },
                "id": f"{workflow_id}_schedule",
                "name": f"⏰ {schedule_hour}:00 Trigger",
                "type": "n8n-nodes-base.scheduleTrigger",
                "typeVersion": 1,
                "position": [250, 400]
            },
            {
                "parameters": {
                    "values": {
                        "string": [
                            {"name": "num_agents", "value": str(agents)},
                            {"name": "max_budget_usd", "value": str(budget)},
                            {"name": "genes", "value": ",".join(genes)},
                            {"name": "optimization_mode", "value": optimization_mode},
                            {"name": "workflow_name", "value": name}
                        ]
                    }
                },
                "id": f"{workflow_id}_config",
                "name": "⚙️ Config",
                "type": "n8n-nodes-base.set",
                "typeVersion": 1,
                "position": [450, 300]
            },
            {
                "parameters": {
                    "command": "cd /Users/paulroma/code/quiver-ep-rna-xgb && python scripts/swarm_cns_stage1_autonomous.py --config '{{$json}}'"
                },
                "id": f"{workflow_id}_execute",
                "name": "🤖 Execute Swarm",
                "type": "n8n-nodes-base.executeCommand",
                "typeVersion": 1,
                "position": [650, 300]
            }
        ],
        "connections": {
            f"{workflow_id}_execute_trigger": {
                "main": [[{"node": f"{workflow_id}_config", "type": "main", "index": 0}]]
            },
            f"{workflow_id}_schedule": {
                "main": [[{"node": f"{workflow_id}_config", "type": "main", "index": 0}]]
            },
            f"{workflow_id}_config": {
                "main": [[{"node": f"{workflow_id}_execute", "type": "main", "index": 0}]]
            }
        },
        "settings": {"executionOrder": "v1"},
        "triggerCount": 2
    }

    return workflow

def generate_bulk_workflows():
    """Generate multiple workflows for different scenarios"""

    workflows = []

    # Scenario 1: Core 5 genes (tonight)
    workflows.append(create_swarm_workflow(
        name="Stage 1 - Core 5 Genes",
        genes=["TSC2", "SCN9A", "SCN10A", "UBE3A", "GABRB3"],
        agents=3,
        budget=50,
        schedule_hour=21  # 9pm
    ))

    # Scenario 2: Epilepsy genes
    workflows.append(create_swarm_workflow(
        name="Stage 2 - Epilepsy Genes",
        genes=["SCN1A", "SCN2A", "SCN8A", "KCNQ2", "KCNQ3", "KCNT1", "STXBP1", "CDKL5"],
        agents=5,
        budget=100,
        schedule_hour=22  # 10pm
    ))

    # Scenario 3: TSC Pathway
    workflows.append(create_swarm_workflow(
        name="TSC Pathway Genes",
        genes=["TSC1", "TSC2", "MTOR", "RHEB", "AKT1", "PTEN"],
        agents=3,
        budget=50,
        schedule_hour=2  # 2am
    ))

    # Scenario 4: Sodium Channels
    workflows.append(create_swarm_workflow(
        name="All Sodium Channels",
        genes=["SCN1A", "SCN2A", "SCN3A", "SCN8A", "SCN9A", "SCN10A", "SCN11A"],
        agents=4,
        budget=70,
        schedule_hour=3  # 3am
    ))

    # Scenario 5: 15q Region
    workflows.append(create_swarm_workflow(
        name="DUP15Q Region",
        genes=["UBE3A", "GABRB3", "GABRA5", "GABRG3", "CHRNA7"],
        agents=3,
        budget=50,
        schedule_hour=23  # 11pm
    ))

    return workflows

def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "help"

    if command == "generate":
        # Generate example workflows
        print("🎯 Generating swarm workflows...\n")

        workflows = generate_bulk_workflows()
        output_dir = Path("workflows/generated")
        output_dir.mkdir(parents=True, exist_ok=True)

        for workflow in workflows:
            filename = output_dir / f"{workflow['name'].lower().replace(' ', '_')}.json"
            with open(filename, "w") as f:
                json.dump(workflow, f, indent=2)
            print(f"  ✓ {workflow['name']}")
            print(f"    → {filename}")

        print(f"\n✅ Generated {len(workflows)} workflows")
        print("\nNow run:")
        print("  bash scripts/n8n_bulk_magic.sh")
        print("  # Or move files: mv workflows/generated/*.json workflows/")

    elif command == "custom":
        # Create custom workflow
        if len(sys.argv) < 4:
            print("Usage: python generate_swarm_workflows.py custom <name> <gene1,gene2,...> [agents] [budget] [hour]")
            sys.exit(1)

        name = sys.argv[2]
        genes = sys.argv[3].split(",")
        agents = int(sys.argv[4]) if len(sys.argv) > 4 else 3
        budget = int(sys.argv[5]) if len(sys.argv) > 5 else 50
        hour = int(sys.argv[6]) if len(sys.argv) > 6 else 21

        workflow = create_swarm_workflow(name, genes, agents, budget, hour)

        output_file = Path(f"workflows/{name.lower().replace(' ', '_')}.json")
        with open(output_file, "w") as f:
            json.dump(workflow, f, indent=2)

        print(f"✓ Created: {output_file}")
        print(f"  Genes: {', '.join(genes)}")
        print(f"  Agents: {agents}")
        print(f"  Budget: ${budget}")
        print(f"  Schedule: {hour}:00")

    elif command == "help":
        print("""
╔═══════════════════════════════════════════════════════════╗
║  Swarm Workflow Generator - Create 50+ Workflows Fast    ║
╚═══════════════════════════════════════════════════════════╝

Commands:
  generate        Generate example workflows (5 scenarios)
  custom          Create custom workflow

Examples:
  # Generate 5 example workflows
  python scripts/generate_swarm_workflows.py generate

  # Create custom workflow
  python scripts/generate_swarm_workflows.py custom "My Swarm" TSC1,TSC2,MTOR 3 50 21

  # Custom with specific parameters:
  #   Name: "ALS Study"
  #   Genes: SOD1,C9orf72,TARDBP
  #   Agents: 5
  #   Budget: $100
  #   Schedule: 2am (hour 2)
  python scripts/generate_swarm_workflows.py custom "ALS Study" SOD1,C9orf72,TARDBP 5 100 2

After generating:
  # Import all at once
  bash scripts/n8n_bulk_magic.sh

  # Or move to workflows directory
  mv workflows/generated/*.json workflows/

Quick Workflow Pipeline:
  1. python scripts/generate_swarm_workflows.py generate
  2. bash scripts/n8n_bulk_magic.sh
  3. open http://localhost:5678
  4. Done! 5+ workflows ready to schedule

Create 50 Workflows:
  # Generate 50 different gene combinations
  for i in {1..50}; do
    python scripts/generate_swarm_workflows.py custom \\
      "Swarm_$i" \\
      "GENE$i,GENE$((i+1)),GENE$((i+2))" \\
      3 50 $((i % 24))
  done

  # Import all 50
  bash scripts/n8n_bulk_magic.sh
""")
    else:
        print(f"Unknown command: {command}")
        print("Run: python scripts/generate_swarm_workflows.py help")
        sys.exit(1)

if __name__ == "__main__":
    main()
