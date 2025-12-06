# PT Performance Platform - Deployment Guide

Complete guide for deploying all components of the PT Performance Platform to production.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Supabase Database Setup](#supabase-database-setup)
3. [iOS App Deployment (TestFlight)](#ios-app-deployment)
4. [Agent Service Deployment](#agent-service-deployment)
5. [Environment Variables Reference](#environment-variables-reference)
6. [Monitoring & Health Checks](#monitoring--health-checks)
7. [Rollback Procedures](#rollback-procedures)

---

## Prerequisites

### Required Accounts
- **Supabase** account with project created
- **Apple Developer** account ($99/year)
- **Cloud hosting** (Railway, Render, or AWS)
- **Linear** workspace for issue tracking

### Required Tools
```bash
# Supabase CLI
brew install supabase/tap/supabase

# iOS Development
# - Xcode 15+ (from App Store)
# - iOS 17+ SDK

# Node.js for agent service
brew install node@20

# Git
brew install git
```

---

## Supabase Database Setup

### 1. Create Project
```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref <YOUR_PROJECT_ID>
```

### 2. Deploy Schema
```bash
cd clients/linear-bootstrap

# Run migrations (applies schema)
supabase db push

# Verify migrations
supabase db remote status
```

### 3. Seed Database
```bash
# Seed exercise library
psql $DATABASE_URL < infra/004_seed_exercise_library.sql

# Seed demo data (optional for testing)
psql $DATABASE_URL < infra/003_seed_demo_data.sql
```

### 4. Configure Auth
In Supabase Dashboard:
1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Configure **Email Templates**:
   - Magic Link template
   - Password Reset template

### 5. Enable Row Level Security (RLS)
Schema already includes RLS policies. Verify:
```sql
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public';
```

### 6. Get API Keys
From Supabase Dashboard → **Settings** → **API**:
- `SUPABASE_URL`: Your project URL
- `SUPABASE_ANON_KEY`: Public anonymous key
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key (keep secret!)

---

## iOS App Deployment

### 1. Xcode Configuration

Open `PTPerformance.xcodeproj` and configure:

**Signing & Capabilities**:
- Team: Select your Apple Developer team
- Bundle Identifier: `com.ptperformance.app` (or your domain)
- Signing: Automatic

**Info.plist**:
Add Supabase URL:
```xml
<key>SupabaseURL</key>
<string>https://your-project.supabase.co</string>
<key>SupabaseAnonKey</key>
<string>your-anon-key-here</string>
```

### 2. Build Configuration

**Create release build**:
```bash
# Clean build folder
Product → Clean Build Folder (⇧⌘K)

# Archive
Product → Archive (⌘B with Release scheme)
```

### 3. TestFlight Deployment

**In Xcode Organizer**:
1. Select archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Select **Upload**
5. Configure options:
   - ✅ Include bitcode (if available)
   - ✅ Upload symbols
   - ✅ Manage version automatically

**In App Store Connect**:
1. Go to **TestFlight** tab
2. Select uploaded build
3. Add **What to Test** notes
4. Add internal testers
5. Click **Save** and **Enable Testing**

### 4. Production Release

**Prepare App Store listing**:
1. Screenshots (required sizes):
   - 6.7" (iPhone 14 Pro Max)
   - 6.5" (iPhone 11 Pro Max)
   - 5.5" (iPhone 8 Plus)
2. App Description
3. Keywords
4. Support URL
5. Privacy Policy URL

**Submit for Review**:
1. Select TestFlight build
2. Add to **App Store** version
3. Complete questionnaire
4. Submit for review

---

## Agent Service Deployment

### Option 1: Railway Deployment (Recommended)

**1. Create Railway project**:
```bash
npm install -g railway
railway login
railway init
```

**2. Configure environment**:
```bash
# In Railway dashboard, add variables:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
LINEAR_API_KEY=your-linear-api-key
PORT=3000
NODE_ENV=production
```

**3. Deploy**:
```bash
cd clients/linear-bootstrap/agent-service
railway up
```

**4. Configure domain**:
- Railway provides: `your-app.railway.app`
- Or add custom domain in Railway settings

### Option 2: Docker Deployment

**1. Build image**:
```bash
cd clients/linear-bootstrap/agent-service

docker build -t pt-performance-agent .
```

**2. Run container**:
```bash
docker run -d \
  --name pt-agent \
  -p 3000:3000 \
  -e SUPABASE_URL=https://your-project.supabase.co \
  -e SUPABASE_SERVICE_ROLE_KEY=your-key \
  -e LINEAR_API_KEY=your-key \
  pt-performance-agent
```

**3. Deploy to cloud**:
```bash
# Push to Docker Hub
docker tag pt-performance-agent your-username/pt-performance-agent
docker push your-username/pt-performance-agent

# Deploy to cloud provider (AWS, GCP, Azure)
# See provider-specific instructions
```

### Option 3: Node.js Direct Deployment

**On your server**:
```bash
# Clone repo
git clone <your-repo-url>
cd clients/linear-bootstrap/agent-service

# Install dependencies
npm install --production

# Create .env file
cat > .env << 'EOL'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-key
LINEAR_API_KEY=your-key
PORT=3000
NODE_ENV=production
EOL

# Start with PM2
npm install -g pm2
pm2 start src/server.js --name pt-agent
pm2 save
pm2 startup
```

---

## Environment Variables Reference

### Supabase Variables

| Variable | Description | Where to Get | Required |
|----------|-------------|--------------|----------|
| `SUPABASE_URL` | Project URL | Dashboard → Settings → API | ✅ |
| `SUPABASE_ANON_KEY` | Public key (client-side) | Dashboard → Settings → API | ✅ |
| `SUPABASE_SERVICE_ROLE_KEY` | Service key (server-side) | Dashboard → Settings → API | ✅ (agent only) |

### Linear Variables

| Variable | Description | Where to Get | Required |
|----------|-------------|--------------|----------|
| `LINEAR_API_KEY` | API access token | Settings → API → Personal API keys | ✅ (agent only) |
| `LINEAR_TEAM_ID` | Team identifier | From GraphQL query | Optional |

### Agent Service Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PORT` | HTTP port | 3000 | No |
| `NODE_ENV` | Environment | development | No |
| `LOG_LEVEL` | Logging level | info | No |

---

## Monitoring & Health Checks

### Agent Service Health Check
```bash
curl https://your-agent-service.com/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2025-12-06T12:00:00Z",
  "services": {
    "supabase": "connected",
    "linear": "connected"
  }
}
```

### Supabase Health
```bash
# Check database
psql $DATABASE_URL -c "SELECT 1"

# Check API
curl https://your-project.supabase.co/rest/v1/
```

### iOS App Crash Reporting
Configure in Xcode:
1. Product → Scheme → Edit Scheme
2. Run → Diagnostics
3. ✅ Address Sanitizer
4. ✅ Thread Sanitizer

View crash reports:
- Xcode → Window → Organizer → Crashes
- App Store Connect → TestFlight → Crashes

---

## Rollback Procedures

### Database Rollback
```bash
# List migrations
supabase migration list

# Rollback last migration
supabase db reset

# Rollback to specific migration
supabase db reset --version <timestamp>
```

### iOS App Rollback
1. App Store Connect → App Store
2. Select previous version
3. Click **+ Version or Platform**
4. Submit previous build

### Agent Service Rollback

**Railway**:
```bash
railway rollback
```

**Docker**:
```bash
# Stop current
docker stop pt-agent

# Start previous version
docker run -d --name pt-agent <previous-image>
```

**PM2**:
```bash
git checkout <previous-commit>
pm2 restart pt-agent
```

---

## Troubleshooting

### Supabase Connection Issues
```bash
# Test connection
psql $DATABASE_URL

# Check RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

### iOS Build Errors
- Clean build folder: `⇧⌘K`
- Delete derived data: `~/Library/Developer/Xcode/DerivedData/`
- Reinstall pods (if using): `pod install`

### Agent Service Errors
```bash
# Check logs
pm2 logs pt-agent

# Check environment
env | grep SUPABASE
env | grep LINEAR
```

---

## Security Checklist

Before production deployment:

- [ ] Supabase RLS policies enabled
- [ ] API keys stored in environment variables (not code)
- [ ] iOS app uses HTTPS for all requests
- [ ] Agent service runs over HTTPS
- [ ] Database backups configured
- [ ] Error logging enabled (no sensitive data in logs)
- [ ] Rate limiting enabled on API endpoints
- [ ] CORS configured correctly

---

## Support & Resources

- **Supabase Docs**: https://supabase.com/docs
- **Apple Developer**: https://developer.apple.com/documentation/
- **Linear API**: https://developers.linear.app/
- **Railway Docs**: https://docs.railway.app/

---

**Last Updated**: 2025-12-06  
**Version**: 1.0.0
