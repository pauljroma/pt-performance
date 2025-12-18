#!/usr/bin/env python3.11
"""
OpenAI Reasoning MCP Server

Enables Claude to consult OpenAI o1 for complex reasoning tasks.
Uses o1-preview (latest reasoning model) for deep analysis.

Author: claude-code-agent
Date: 2025-12-03
Version: 1.0
"""

import asyncio
import json
import os
from typing import Dict, Optional, List
from datetime import datetime
import httpx

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


class OpenAIReasoningMCP:
    """MCP server for OpenAI o1 reasoning."""

    def __init__(self):
        self.app = Server("openai-reasoning")

        # Configuration
        self.api_key = os.getenv("OPENAI_API_KEY", "")
        self.base_url = "https://api.openai.com/v1"

        # Model configuration (o1-preview is latest as of Dec 2024)
        # Note: Check OpenAI docs for o1 variants (o1-preview, o1-mini)
        self.default_model = os.getenv("OPENAI_O1_MODEL", "o1-preview")
        self.max_tokens = int(os.getenv("OPENAI_O1_MAX_TOKENS", "16000"))

        # Cost tracking
        self.metrics = {
            'consultations_total': 0,
            'total_cost_usd': 0.0,
            'total_input_tokens': 0,
            'total_output_tokens': 0,
            'average_reasoning_time_sec': 0.0
        }

        # Budget limits
        self.daily_budget_usd = float(os.getenv("OPENAI_DAILY_BUDGET", "10.00"))
        self.per_consultation_max_usd = float(os.getenv("OPENAI_PER_CALL_MAX", "2.00"))

        self._register_handlers()

    def _register_handlers(self):
        """Register MCP handlers."""

        @self.app.list_tools()
        async def list_tools() -> list[Tool]:
            return [
                Tool(
                    name="consult_o1",
                    description="Consult OpenAI o1 for complex reasoning (use sparingly - expensive)",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "problem": {
                                "type": "string",
                                "description": "Complex problem requiring deep reasoning"
                            },
                            "context": {
                                "type": "string",
                                "description": "Additional context (constraints, requirements, current state)"
                            },
                            "requested_output": {
                                "type": "string",
                                "description": "What kind of output you need (plan, analysis, recommendation, etc.)"
                            },
                            "model": {
                                "type": "string",
                                "enum": ["o1-preview", "o1-mini"],
                                "description": "Model to use (o1-preview for complex, o1-mini for simpler)",
                                "default": "o1-preview"
                            }
                        },
                        "required": ["problem", "requested_output"]
                    }
                ),
                Tool(
                    name="deep_analysis",
                    description="Request deep analysis of architecture/design decision",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "decision": {
                                "type": "string",
                                "description": "Decision to analyze (e.g., 'microservices vs monolith')"
                            },
                            "options": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Options being considered"
                            },
                            "context": {
                                "type": "string",
                                "description": "Context (team size, timeline, constraints)"
                            }
                        },
                        "required": ["decision", "options"]
                    }
                ),
                Tool(
                    name="plan_strategy",
                    description="Request strategic planning for complex multi-phase project",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "project": {
                                "type": "string",
                                "description": "Project description"
                            },
                            "goals": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Project goals"
                            },
                            "constraints": {
                                "type": "string",
                                "description": "Constraints (time, budget, resources)"
                            }
                        },
                        "required": ["project", "goals"]
                    }
                ),
                Tool(
                    name="get_reasoning_metrics",
                    description="Get OpenAI o1 usage metrics and costs",
                    inputSchema={
                        "type": "object",
                        "properties": {}
                    }
                )
            ]

        @self.app.call_tool()
        async def call_tool(name: str, arguments: dict) -> list[TextContent]:
            try:
                # Check API key
                if not self.api_key:
                    return [TextContent(
                        type="text",
                        text="❌ OpenAI API key not configured\n\n"
                             "Set OPENAI_API_KEY environment variable:\n"
                             "```bash\n"
                             "export OPENAI_API_KEY=sk-proj-...\n"
                             "```"
                    )]

                if name == "consult_o1":
                    return await self._consult_o1(arguments)
                elif name == "deep_analysis":
                    return await self._deep_analysis(arguments)
                elif name == "plan_strategy":
                    return await self._plan_strategy(arguments)
                elif name == "get_reasoning_metrics":
                    return await self._get_metrics(arguments)
                else:
                    return [TextContent(type="text", text=f"❌ Unknown tool: {name}")]
            except Exception as e:
                return [TextContent(type="text", text=f"❌ Error: {str(e)}")]

    # ========================================================================
    # TOOL IMPLEMENTATIONS
    # ========================================================================

    async def _consult_o1(self, args: dict) -> list[TextContent]:
        """Consult OpenAI o1 for complex reasoning."""
        problem = args.get("problem", "")
        context = args.get("context", "")
        requested_output = args.get("requested_output", "")
        model = args.get("model", self.default_model)

        if not problem:
            return [TextContent(type="text", text="❌ problem is required")]

        # Check budget
        budget_check = self._check_budget()
        if not budget_check["allowed"]:
            return [TextContent(
                type="text",
                text=f"❌ Budget exceeded\n\n{budget_check['message']}"
            )]

        # Build prompt
        prompt = f"""Problem: {problem}

Context: {context if context else 'None provided'}

Requested Output: {requested_output}

Please provide:
1. Deep analysis of the problem
2. Key tradeoffs and considerations
3. Recommended approach with reasoning
4. Implementation steps (if applicable)"""

        # Call o1
        start_time = asyncio.get_event_loop().time()

        try:
            response = await self._call_openai_o1(prompt, model)

            end_time = asyncio.get_event_loop().time()
            reasoning_time = end_time - start_time

            # Update metrics
            self._update_metrics(
                response["usage"],
                reasoning_time,
                model
            )

            # Format response
            output = f"# o1 Reasoning Results\n\n"
            output += f"**Model**: {model}\n"
            output += f"**Reasoning Time**: {reasoning_time:.1f}s\n"
            output += f"**Cost**: ${response['cost']:.4f}\n\n"
            output += "---\n\n"
            output += response["content"]
            output += f"\n\n---\n\n"
            output += f"**Tokens**: {response['usage']['prompt_tokens']} in, "
            output += f"{response['usage']['completion_tokens']} out\n"
            output += f"**Daily Budget**: ${self.metrics['total_cost_usd']:.2f} / ${self.daily_budget_usd:.2f}"

            return [TextContent(type="text", text=output)]

        except Exception as e:
            return [TextContent(
                type="text",
                text=f"❌ OpenAI API error: {str(e)}\n\n"
                     "Check:\n"
                     "1. API key is valid\n"
                     "2. You have access to o1 models\n"
                     "3. Your OpenAI account has credits"
            )]

    async def _deep_analysis(self, args: dict) -> list[TextContent]:
        """Request deep analysis of decision."""
        decision = args.get("decision", "")
        options = args.get("options", [])
        context = args.get("context", "")

        prompt = f"""I need deep analysis of this decision:

Decision: {decision}

Options:
{chr(10).join(f"{i+1}. {opt}" for i, opt in enumerate(options))}

Context: {context if context else 'General use case'}

Please provide:
1. Pros and cons of each option
2. Key tradeoffs
3. Recommended choice with reasoning
4. Risk mitigation strategies
5. Migration path (if switching from current state)"""

        return await self._consult_o1({
            "problem": prompt,
            "requested_output": "Detailed analysis with recommendation"
        })

    async def _plan_strategy(self, args: dict) -> list[TextContent]:
        """Request strategic planning."""
        project = args.get("project", "")
        goals = args.get("goals", [])
        constraints = args.get("constraints", "")

        prompt = f"""I need strategic planning for this project:

Project: {project}

Goals:
{chr(10).join(f"- {goal}" for goal in goals)}

Constraints: {constraints if constraints else 'None specified'}

Please provide:
1. High-level phases
2. Key milestones
3. Dependencies and critical path
4. Risk assessment
5. Success criteria
6. Resource allocation recommendations"""

        return await self._consult_o1({
            "problem": prompt,
            "requested_output": "Strategic plan with phases and milestones"
        })

    async def _get_metrics(self, args: dict) -> list[TextContent]:
        """Get usage metrics."""
        output = f"# OpenAI o1 Usage Metrics\n\n"
        output += f"**Total Consultations**: {self.metrics['consultations_total']}\n"
        output += f"**Total Cost**: ${self.metrics['total_cost_usd']:.2f}\n"
        output += f"**Daily Budget**: ${self.daily_budget_usd:.2f}\n"
        output += f"**Budget Used**: {(self.metrics['total_cost_usd'] / self.daily_budget_usd * 100):.1f}%\n\n"

        output += f"**Total Input Tokens**: {self.metrics['total_input_tokens']:,}\n"
        output += f"**Total Output Tokens**: {self.metrics['total_output_tokens']:,}\n"
        output += f"**Avg Reasoning Time**: {self.metrics['average_reasoning_time_sec']:.1f}s\n\n"

        output += "## Pricing (o1-preview)\n"
        output += "- Input: $15 / 1M tokens\n"
        output += "- Output: $60 / 1M tokens\n\n"

        output += "## Pricing (o1-mini)\n"
        output += "- Input: $3 / 1M tokens\n"
        output += "- Output: $12 / 1M tokens\n\n"

        output += "💡 **Tip**: Use o1-mini for simpler reasoning to save costs"

        return [TextContent(type="text", text=output)]

    # ========================================================================
    # OPENAI API INTEGRATION
    # ========================================================================

    async def _call_openai_o1(self, prompt: str, model: str) -> dict:
        """Call OpenAI o1 API."""
        async with httpx.AsyncClient(timeout=180.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": model,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    "max_completion_tokens": self.max_tokens
                }
            )

            response.raise_for_status()
            data = response.json()

            # Calculate cost
            usage = data["usage"]
            cost = self._calculate_cost(usage, model)

            return {
                "content": data["choices"][0]["message"]["content"],
                "usage": usage,
                "cost": cost,
                "model": model
            }

    def _calculate_cost(self, usage: dict, model: str) -> float:
        """Calculate cost based on token usage."""
        # Pricing as of Dec 2024
        pricing = {
            "o1-preview": {"input": 15.0, "output": 60.0},  # per 1M tokens
            "o1-mini": {"input": 3.0, "output": 12.0},
            "o1": {"input": 15.0, "output": 60.0}  # fallback
        }

        model_pricing = pricing.get(model, pricing["o1"])

        input_cost = (usage["prompt_tokens"] / 1_000_000) * model_pricing["input"]
        output_cost = (usage["completion_tokens"] / 1_000_000) * model_pricing["output"]

        return input_cost + output_cost

    def _check_budget(self) -> dict:
        """Check if budget allows another consultation."""
        if self.metrics['total_cost_usd'] >= self.daily_budget_usd:
            return {
                "allowed": False,
                "message": f"Daily budget of ${self.daily_budget_usd:.2f} exceeded\n"
                          f"Current spend: ${self.metrics['total_cost_usd']:.2f}"
            }

        return {"allowed": True}

    def _update_metrics(self, usage: dict, reasoning_time: float, model: str):
        """Update usage metrics."""
        cost = self._calculate_cost(usage, model)

        self.metrics['consultations_total'] += 1
        self.metrics['total_cost_usd'] += cost
        self.metrics['total_input_tokens'] += usage["prompt_tokens"]
        self.metrics['total_output_tokens'] += usage["completion_tokens"]

        # Update average reasoning time
        n = self.metrics['consultations_total']
        old_avg = self.metrics['average_reasoning_time_sec']
        self.metrics['average_reasoning_time_sec'] = (old_avg * (n - 1) + reasoning_time) / n

    # ========================================================================
    # SERVER LIFECYCLE
    # ========================================================================

    async def run(self):
        """Run the MCP server."""
        async with stdio_server() as (read_stream, write_stream):
            await self.app.run(
                read_stream,
                write_stream,
                self.app.create_initialization_options()
            )


# ============================================================================
# MAIN
# ============================================================================

async def main():
    """Run OpenAI reasoning MCP server."""
    server = OpenAIReasoningMCP()
    await server.run()


if __name__ == "__main__":
    asyncio.run(main())
