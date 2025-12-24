# Q1 2025 Linear Issues - Quick Reference

## Summary

✅ **107/107 issues created successfully**
- Build 72: ACP-285 to ACP-300 (16 issues)
- Build 73: ACP-301 to ACP-318 (18 issues)
- Build 74: ACP-319 to ACP-326 (8 issues)
- Build 75: ACP-327 to ACP-341 (15 issues)
- Build 76: ACP-342 to ACP-351 (10 issues)
- Build 77: ACP-352 to ACP-359 (8 issues)
- Build 78: ACP-360 to ACP-371 (12 issues)
- Build 79: ACP-372 to ACP-381 (10 issues)
- Build 80: ACP-382 to ACP-391 (10 issues)

## View in Linear

**All Q1 Issues:** https://linear.app/x2machines/team/ACP

**Filter:** `number >= 285 AND number <= 391`

## Issue Ranges by Build

| Build | Issues | Count | Focus Area |
|-------|--------|-------|------------|
| 72 | ACP-285 to ACP-300 | 16 | Readiness Auto-Adjustment |
| 73 | ACP-301 to ACP-318 | 18 | Safety Alerts & Workload Flags |
| 74 | ACP-319 to ACP-326 | 8 | Video Library + Help System |
| 75 | ACP-327 to ACP-341 | 15 | Return-to-Play Protocols |
| 76 | ACP-342 to ACP-351 | 10 | Daily Habit Loop & Streaks |
| 77 | ACP-352 to ACP-359 | 8 | Universal Block-Based Logging |
| 78 | ACP-360 to ACP-371 | 12 | Joint-Specific Intelligence |
| 79 | ACP-372 to ACP-381 | 10 | Documentation Automation |
| 80 | ACP-382 to ACP-391 | 10 | PT → S&C Handoff Workflow |

## Parent Epics

- **ACP-275:** AI-Driven Program Intelligence Layer
- **ACP-276:** Return-to-Play Intelligence (Builds 75, 80)
- **ACP-277:** Readiness & Auto-Regulation Engine (Builds 72, 76)
- **ACP-278:** Parity - Program Builder & Periodization (Builds 77, 79)
- **ACP-279:** Parity - Athlete Assignment & Delivery
- **ACP-280:** Intelligent Exercise Library (Build 74)
- **ACP-281:** Pain Interpretation & Safety System (Build 73)
- **ACP-282:** Analytics & Predictive Intelligence (Build 78)
- **ACP-283:** Collaboration & Communication Hub
- **ACP-284:** Video Intelligence & Form Analysis

## Scripts

1. **Create Build 72:**
   ```bash
   cd clients/linear-bootstrap
   python3 create_q1_2025_issues_complete.py
   ```

2. **Create Builds 73-80:**
   ```bash
   cd clients/linear-bootstrap
   python3 create_builds_73_80.py
   ```

## Verification

All issues verified in Linear:
```bash
python3 -c "import requests; ..."  # See BUILD_72A_AGENT_2_COMPLETE.md
```

## Next Steps

- Agent 3: Create Q2 2025 issues (Builds 81-90)
- Agent 9: Integrate all BUILD_72A components

