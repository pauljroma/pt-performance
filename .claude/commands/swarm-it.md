Execute the most recent task using swarm coordination with self-grading.

## Instructions

You are executing a swarm task. Follow these steps:

1. **Create Estimate** (.estimates/estimate_[task]_[timestamp].json)
   - Agents required
   - Estimated time
   - Dependencies and risks

2. **Create Swarm Plan** (.swarms/[task]_v1.yaml)
   - Phases with agents
   - Deliverables per agent
   - Enforcement checks
   - Acceptance criteria

3. **Execute Swarm**
   - Work through each phase sequentially
   - Mark agents as completed when done
   - Track all deliverables

4. **Self-Grade** (.outcomes/[task]_[timestamp].json)
   - Grade on: completeness, quality, compliance, efficiency, reusability
   - Weight: 25%, 25%, 20%, 15%, 15%
   - Provide letter grade (A+, A, B, etc.)
   - Compare estimate vs actual

5. **Generate Backlog Items** (.backlog/backlog-[task]-[n].json)
   - HIGH/MEDIUM/LOW priority
   - Next steps for future work

## Grading Rubric

| Grade | Score | Description |
|-------|-------|-------------|
| A+ | 95-100 | Exceptional - Exceeds all requirements |
| A | 90-94 | Excellent - Meets all requirements with high quality |
| B | 80-89 | Good - Meets most requirements |
| C | 70-79 | Acceptable - Meets minimum requirements |
| D | 60-69 | Poor - Missing requirements |
| F | <60 | Failing - Incomplete |

## Output Format

At the end, provide a summary showing:
- ✅ Deliverables completed
- 📊 Final grade
- ⏱️ Estimate vs actual time
- 📝 Backlog items generated
- 🔗 Links to outcome files
