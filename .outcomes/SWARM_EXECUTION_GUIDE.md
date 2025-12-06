# Swarm Execution Guide - Phase 1
**Started:** 2025-12-06
**Status:** Active (3 agents running)
**Estimated Completion:** 6-8 hours

---

## Swarm Overview

**Mission:** Deploy complete Supabase data layer for PT Performance Platform

**Agents:** 3 parallel agents working in isolated zones

**Coordination:** Linear issue comments + swarm plan

**Plan File:** `.swarms/phase1_data_layer_v1.yaml`

---

## Active Agents

### Agent 1: Schema & Tables (zone-7, zone-8)
**Agent ID:** 6a278ea7
**Linear Issues:** ACP-83, ACP-69, ACP-79

**Tasks:**
1. Validate and apply Supabase schema from infra/*.sql
2. Add CHECK constraints (pain/RPE/velocity)
3. Build protocol schema (3 tables)

**Expected Deliverables:**
- 20+ tables created in Supabase
- CHECK constraints enforced
- Protocol tables with sample data
- Screenshot of Supabase dashboard

### Agent 2: Views & Analytics (zone-7, zone-10b)
**Agent ID:** e3b0af96
**Linear Issues:** ACP-85, ACP-64, ACP-70

**Tasks:**
1. Create analytics views (adherence, pain trend, throwing workload)
2. Implement throwing-specific views
3. Create data quality view

**Expected Deliverables:**
- 5 views created and tested
- Performance <500ms per view
- Sample queries documented
- DATA_DICTIONARY.md updated

### Agent 3: Seed & Test (zone-7, zone-8, zone-10b)
**Agent ID:** 6d16ce1b
**Linear Issues:** ACP-84, ACP-67, ACP-86

**Tasks:**
1. Seed demo data (therapist, patient, program)
2. Seed exercise library (50-100 exercises)
3. Implement data quality tests

**Expected Deliverables:**
- Demo patient: John Brebbia (fully profiled)
- 8-week program (24 sessions)
- 50+ exercises with metadata
- Unit tests passing
- Quality report: 0 issues

---

## Monitoring Commands

### Check Linear Issues
Visit: https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

Filter by:
```
ACP-83 OR ACP-69 OR ACP-79 OR ACP-85 OR ACP-64 OR ACP-70 OR ACP-84 OR ACP-67 OR ACP-86
```

### Check Agent Status
Agents will complete and report back automatically. You can check progress anytime by:
1. Opening Linear issues
2. Reading agent comments
3. Checking issue status (Backlog → In Progress → Done)

---

## Validation After Completion

When all agents report completion, run these validation tests:

### SQL Validation
```sql
-- Test 1: Verify all tables exist
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'public';
-- Expected: >= 20 tables

-- Test 2: Verify views work
SELECT * FROM vw_patient_adherence LIMIT 5;
SELECT * FROM vw_pain_trend LIMIT 5;
SELECT * FROM vw_throwing_workload LIMIT 5;
SELECT * FROM vw_data_quality_issues;
-- Expected: All queries return results, vw_data_quality_issues returns 0 rows

-- Test 3: Verify demo patient
SELECT * FROM patients
WHERE first_name = 'John' AND last_name = 'Brebbia';
-- Expected: 1 row returned with full profile

-- Test 4: Verify program structure
SELECT p.name, COUNT(DISTINCT ph.id) AS phases, COUNT(DISTINCT s.id) AS sessions
FROM programs p
LEFT JOIN phases ph ON ph.program_id = p.id
LEFT JOIN sessions s ON s.phase_id = ph.id
WHERE p.name = '8-Week On-Ramp'
GROUP BY p.name;
-- Expected: 1 program, 4 phases, 24 sessions

-- Test 5: Verify exercise library
SELECT category, COUNT(*) AS exercise_count
FROM exercise_templates
GROUP BY category;
-- Expected: >= 50 total exercises across categories

-- Test 6: Verify CHECK constraints
INSERT INTO pain_logs (patient_id, session_id, pain_during, pain_after)
VALUES ('test-id', 'test-id', 15, 15);
-- Expected: Error (CHECK constraint violation)
```

### Success Criteria Checklist
- [ ] All tables created (20+)
- [ ] All views execute without errors (5 views)
- [ ] Demo patient exists with full profile
- [ ] 8-week program seeded (4 phases, 24 sessions)
- [ ] Exercise library populated (50+ exercises)
- [ ] CHECK constraints enforced (pain, RPE, velocity)
- [ ] Data quality view returns 0 issues
- [ ] All unit tests passing
- [ ] Performance targets met (<500ms views)
- [ ] All Linear issues marked "Done"

---

## What to Do When Swarm Completes

### 1. Review Agent Reports
Each agent will provide:
- Completion status
- Deliverables created
- Any issues encountered
- Linear issue updates

### 2. Run Validation Tests
Execute the SQL validation queries above to verify:
- All tables and views created
- Data integrity maintained
- Performance targets met

### 3. Create Phase 1 Handoff Document
```bash
# Create handoff documenting Phase 1 completion
cat > .outcomes/phase1_handoff.md << 'EOF'
# Phase 1 Complete: Data Layer

## Summary
Phase 1 (Data Layer) completed successfully by 3-agent swarm.

## Deliverables
- Database: [X] All tables created
- Views: [X] All views working
- Demo Data: [X] Patient + program seeded
- Tests: [X] All passing

## Quality Metrics
- Tables: XX created
- Views: 5 created
- Exercises: XX seeded
- Quality Issues: 0

## Next Steps
Ready for Phase 2: Backend Intelligence
EOF
```

### 4. Update Linear Handoff Issue
Update ACP-103 with Phase 1 completion:
```markdown
## Phase 1 Update ✅

Phase 1 (Data Layer) completed by swarm execution.

**Completed:**
- ACP-83, ACP-69, ACP-79 (Schema & Tables) ✅
- ACP-85, ACP-64, ACP-70 (Views & Analytics) ✅
- ACP-84, ACP-67, ACP-86 (Seed & Test) ✅

**Next:** Ready for Phase 2 - Backend Intelligence
```

### 5. Prepare Phase 2 Launch
Review MASTER_EXECUTION_PLAN.md Phase 2 section and prepare swarm command for backend intelligence work.

---

## Troubleshooting

### If Agent Reports Errors

**Supabase Connection Issues:**
- Verify SUPABASE_URL in .env
- Check Supabase project is active
- Test connection manually

**Schema Deployment Fails:**
- Check SQL syntax in infra/*.sql files
- Verify table dependencies/ordering
- Review Supabase error logs

**Data Seeding Issues:**
- Verify tables exist before seeding
- Check foreign key relationships
- Validate data formats (dates, enums, etc.)

**View Creation Fails:**
- Ensure dependent tables exist
- Check column names match schema
- Verify aggregate functions syntax

### If Agents Conflict

Agents are working in isolated zones, so conflicts should be minimal. If conflicts occur:
1. Check Linear issue comments for agent activity
2. Lower-numbered issue (ACP-XX) takes priority
3. Coordinate via Linear comments
4. Resume or retry failed work

---

## Reference Documents

- **MASTER_EXECUTION_PLAN.md** - Overall strategy
- **QUICK_START.md** - Launch procedures
- **.swarms/phase1_data_layer_v1.yaml** - Swarm plan
- **docs/runbooks/RUNBOOK_DATA_SUPABASE.md** - Data layer guide
- **docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md** - Testing

---

## Agent Coordination Protocol

Agents follow this protocol:

**Starting Work:**
```
🤖 Agent X starting work on ACP-XX
Zone: zone-X
Estimated completion: Y hours
Dependencies: [List or None]
```

**Progress Updates (every 30 min):**
```
⏳ In progress - Step X/Y complete
Current: [What agent is doing now]
Blockers: [Any issues or None]
Next: [What's coming next]
```

**Completion:**
```
✅ Work complete on ACP-XX

Deliverables:
- [List what was created]
- [Links to evidence]

Tests:
- [List tests run]
- [All passing ✅ or failures ❌]

Moving to Done
```

---

## Expected Timeline

**Agent 1 (Schema):** 2-3 hours
**Agent 2 (Views):** 2-3 hours (may wait for Agent 1)
**Agent 3 (Seed/Test):** 3-4 hours (may wait for Agents 1 & 2)

**Total:** 6-8 hours (with parallel execution)

---

## Post-Swarm Actions

After Phase 1 completes:

1. **Validate:** Run all validation tests
2. **Document:** Create phase1_handoff.md
3. **Update Linear:** Mark Phase 1 complete
4. **Review:** Check quality metrics
5. **Prepare:** Plan Phase 2 launch

---

**Swarm Status:** 🟢 ACTIVE

**Monitor:** Linear issues for real-time updates

**ETA:** 6-8 hours from start

---

_This guide is updated as swarm progresses_
_Last updated: 2025-12-06_
