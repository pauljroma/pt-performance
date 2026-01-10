# Linear Issue Update Required

## Issues to Update

### ACP-231: Create GitHub Actions CI/CD Pipeline
**Status:** Ready to mark as "Done"

**Update Command:**
```bash
cd /Users/expo/Code/expo
source .env  # Load LINEAR_API_KEY
python3 scripts/linear/update_issue.py \
  --issue ACP-231 \
  --status "Done" \
  --comment "GitHub Actions CI/CD pipeline completed. File: .github/workflows/ios-ci-cd.yml. Features: Lint, unit tests, integration tests, build for simulator, build for device, performance tests, coverage enforcement (70% threshold), artifact retention. Documentation: docs/DEVOPS_GITHUB_SECRETS.md. Status: Production-ready. See BUILD_69_AGENT_19.md for full details."
```

**Deliverable Summary:**
- File: `.github/workflows/ios-ci-cd.yml`
- Features:
  - SwiftLint validation with strict mode
  - Unit tests with 70% coverage threshold
  - Integration tests with Supabase
  - Build for simulator and device
  - Performance benchmarking
  - Artifact retention (30-90 days)
- Status: Production-ready
- Documentation: `docs/DEVOPS_GITHUB_SECRETS.md`

---

### ACP-232: Automated TestFlight Upload
**Status:** Ready to mark as "Done"

**Update Command:**
```bash
cd /Users/expo/Code/expo
source .env  # Load LINEAR_API_KEY
python3 scripts/linear/update_issue.py \
  --issue ACP-232 \
  --status "Done" \
  --comment "Automated TestFlight deployment completed. File: .github/workflows/ios-testflight-deploy.yml. Features: Auto build increment, full test suite, code signing, App Store Connect API upload, GitHub release creation, IPA artifact retention. Triggers: Push to main, manual workflow dispatch. Documentation: docs/DEVOPS_GITHUB_SECRETS.md. Status: Production-ready. See BUILD_69_AGENT_19.md for full details."
```

**Deliverable Summary:**
- File: `.github/workflows/ios-testflight-deploy.yml`
- Features:
  - Automatic build number increment (Git commit count)
  - Manual build number override option
  - Full test suite execution before deployment
  - Code signing with certificates and provisioning
  - App Store Connect API integration
  - GitHub release creation with version tagging
  - IPA artifact upload (90-day retention)
- Triggers:
  - Automatic: Push to main branch
  - Manual: workflow_dispatch with optional build number
- Status: Production-ready
- Documentation: `docs/DEVOPS_GITHUB_SECRETS.md`

---

## Prerequisites

### Linear API Key Setup

**Required:** LINEAR_API_KEY environment variable

**Setup Instructions:**
1. Go to https://linear.app/settings/api
2. Create new API key
3. Add to `.env` file in repository root:
   ```bash
   LINEAR_API_KEY="lin_api_xxxxxxxxxxxxx"
   ```
4. Never commit `.env` to version control (already in .gitignore)

**Verify Setup:**
```bash
cd /Users/expo/Code/expo
source .env
python3 scripts/linear/verify_auth.py
```

---

## Complete Update Process

**Run both updates:**
```bash
cd /Users/expo/Code/expo
source .env

# Update ACP-231
python3 scripts/linear/update_issue.py \
  --issue ACP-231 \
  --status "Done" \
  --comment "GitHub Actions CI/CD pipeline completed. File: .github/workflows/ios-ci-cd.yml. Features: Lint, unit tests, integration tests, build for simulator, build for device, performance tests, coverage enforcement (70% threshold), artifact retention. Documentation: docs/DEVOPS_GITHUB_SECRETS.md. Status: Production-ready. See BUILD_69_AGENT_19.md for full details."

# Update ACP-232
python3 scripts/linear/update_issue.py \
  --issue ACP-232 \
  --status "Done" \
  --comment "Automated TestFlight deployment completed. File: .github/workflows/ios-testflight-deploy.yml. Features: Auto build increment, full test suite, code signing, App Store Connect API upload, GitHub release creation, IPA artifact retention. Triggers: Push to main, manual workflow dispatch. Documentation: docs/DEVOPS_GITHUB_SECRETS.md. Status: Production-ready. See BUILD_69_AGENT_19.md for full details."
```

---

## Verification

After updating, verify in Linear:
1. Go to https://linear.app/agent-control-plane
2. Search for ACP-231 and ACP-232
3. Confirm status is "Done"
4. Check comments are added
5. Verify they're linked to "MVP 1 — PT App & Agent Pilot" project

---

## Related Documentation

- [BUILD_69_AGENT_19.md](./BUILD_69_AGENT_19.md) - Complete build documentation
- [DEVOPS_GITHUB_SECRETS.md](../docs/DEVOPS_GITHUB_SECRETS.md) - Secrets configuration guide
- [LINEAR_RUNBOOK.md](../.claude/LINEAR_RUNBOOK.md) - Linear automation guide
- [ios-ci-cd.yml](../.github/workflows/ios-ci-cd.yml) - CI/CD workflow
- [ios-testflight-deploy.yml](../.github/workflows/ios-testflight-deploy.yml) - Deployment workflow

---

**Created:** 2025-12-19
**Agent:** Agent 19 (DevOps - CI/CD)
**Status:** Ready for Linear update
