# WHOOP API Integration Specification

⚠️ **DEPRECATED - INCORRECT ARCHITECTURE**

This spec incorrectly references Quiver (drug discovery platform) as the backend.
The actual PT Performance backend is **Supabase Edge Functions**, not Quiver.

**Implemented as:**
- `supabase/functions/whoop-oauth-callback/` - OAuth code exchange
- `supabase/functions/whoop-sync-recovery/` - Recovery data sync
- `supabase/migrations/20251224000001_create_whoop_tables.sql` - Database schema

**See instead:** `IOS_WHOOP_INTEGRATION_SPEC.md` for the correct implementation.

---

**Issue:** ACP-465 - Design WHOOP API integration architecture
**Platform:** ~~Quiver (Backend Intelligence Platform)~~ **Supabase Edge Functions**
**Date:** 2025-12-24
**Build:** 76

---

## Overview

Integrate WHOOP API to pull recovery, sleep, and strain data for athletes.

**WHOOP API Documentation:** https://developer.whoop.com/api

---

## Architecture

### Component Location
```
quiver_platform/
  zones/
    z09_integration/              # New zone for external integrations
      whoop/
        __init__.py
        whoop_client.py          # API client
        whoop_models.py          # Data models
        whoop_mapper.py          # WHOOP → PT Performance mapping
        whoop_config.py          # Configuration
```

### Design Principles
1. **OAuth 2.0 Authentication** - Use WHOOP's OAuth flow
2. **Rate Limiting** - Respect WHOOP's rate limits (100 req/min)
3. **Caching** - Cache recovery scores (refresh every 4 hours)
4. **Error Handling** - Graceful degradation if WHOOP unavailable

---

## WHOOP API Client

### File: `whoop_client.py`

```python
"""WHOOP API Client for PT Performance integration."""

import requests
from typing import Optional, Dict, List
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class WHOOPClient:
    """Client for WHOOP API v2.0"""

    API_BASE = "https://api.whoop.com/v1"

    def __init__(self, access_token: str):
        """
        Initialize WHOOP client.

        Args:
            access_token: WHOOP OAuth access token
        """
        self.access_token = access_token
        self.headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

    def get_recovery(self, date: Optional[datetime] = None) -> Dict:
        """
        Get recovery data for a specific date.

        Args:
            date: Date to fetch recovery for (default: today)

        Returns:
            Recovery data including HRV, RHR, sleep performance
        """
        if date is None:
            date = datetime.now()

        url = f"{self.API_BASE}/recovery"
        params = {"date": date.strftime("%Y-%m-%d")}

        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"WHOOP API error: {e}")
            raise

    def get_sleep(self, start_date: datetime, end_date: datetime) -> List[Dict]:
        """
        Get sleep data for a date range.

        Args:
            start_date: Start of range
            end_date: End of range

        Returns:
            List of sleep records
        """
        url = f"{self.API_BASE}/sleep"
        params = {
            "start": start_date.isoformat(),
            "end": end_date.isoformat()
        }

        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            response.raise_for_status()
            return response.json().get("records", [])
        except requests.exceptions.RequestException as e:
            logger.error(f"WHOOP sleep API error: {e}")
            raise

    def get_strain(self, date: Optional[datetime] = None) -> Dict:
        """
        Get strain data for a specific date.

        Args:
            date: Date to fetch strain for (default: today)

        Returns:
            Strain data including day strain, workout strain
        """
        if date is None:
            date = datetime.now()

        url = f"{self.API_BASE}/cycle"
        params = {"date": date.strftime("%Y-%m-%d")}

        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"WHOOP strain API error: {e}")
            raise
```

---

## Recovery Score → Readiness Band Mapping

### File: `whoop_mapper.py`

```python
"""Map WHOOP data to PT Performance readiness bands."""

from enum import Enum
from typing import Dict


class ReadinessBand(Enum):
    """PT Performance readiness bands"""
    GREEN = "green"      # 67-100%
    YELLOW = "yellow"    # 34-66%
    RED = "red"          # 0-33%


class WHOOPMapper:
    """Map WHOOP recovery scores to PT Performance readiness bands"""

    @staticmethod
    def recovery_to_readiness_band(recovery_score: float) -> ReadinessBand:
        """
        Convert WHOOP recovery score (0-100) to readiness band.

        WHOOP Recovery Interpretation:
        - 67-100%: Green (high recovery, ready for high load)
        - 34-66%:  Yellow (moderate recovery, moderate load)
        - 0-33%:   Red (low recovery, prioritize rest/recovery)

        Args:
            recovery_score: WHOOP recovery percentage (0-100)

        Returns:
            ReadinessBand enum
        """
        if recovery_score >= 67:
            return ReadinessBand.GREEN
        elif recovery_score >= 34:
            return ReadinessBand.YELLOW
        else:
            return ReadinessBand.RED

    @staticmethod
    def recovery_to_session_adjustment(recovery_score: float) -> Dict:
        """
        Calculate session volume/intensity adjustments based on recovery.

        Auto-Adjustment Logic:
        - Green (67-100%): 100% volume, can push intensity
        - Yellow (34-66%): 80-90% volume, moderate intensity
        - Red (0-33%):     60-70% volume, low intensity or rest day

        Args:
            recovery_score: WHOOP recovery percentage

        Returns:
            Adjustment recommendations
        """
        if recovery_score >= 67:
            return {
                "volume_multiplier": 1.0,
                "intensity_recommendation": "high",
                "session_notes": "High recovery - ready for demanding sessions"
            }
        elif recovery_score >= 34:
            return {
                "volume_multiplier": 0.85,
                "intensity_recommendation": "moderate",
                "session_notes": "Moderate recovery - reduce volume slightly"
            }
        else:
            return {
                "volume_multiplier": 0.65,
                "intensity_recommendation": "low",
                "session_notes": "Low recovery - prioritize technique/mobility"
            }

    @staticmethod
    def hrv_to_readiness_modifier(hrv_ms: float, baseline_hrv: float) -> float:
        """
        Calculate readiness modifier based on HRV deviation from baseline.

        Args:
            hrv_ms: Current HRV in milliseconds
            baseline_hrv: Athlete's baseline HRV

        Returns:
            Modifier (-0.1 to +0.1)
        """
        deviation = (hrv_ms - baseline_hrv) / baseline_hrv

        # HRV > 10% above baseline: +0.1 modifier (extra readiness)
        # HRV > 10% below baseline: -0.1 modifier (reduced readiness)
        return max(-0.1, min(0.1, deviation))
```

---

## Data Models

### File: `whoop_models.py`

```python
"""WHOOP data models."""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class WHOOPRecovery:
    """WHOOP recovery data"""
    date: datetime
    recovery_score: float  # 0-100
    hrv_rmssd: float      # HRV in milliseconds
    resting_hr: int       # Resting heart rate
    hrv_baseline: float   # Athlete's HRV baseline
    sleep_performance: float  # Sleep quality 0-100

    @property
    def readiness_band(self) -> str:
        """Get PT Performance readiness band"""
        from .whoop_mapper import WHOOPMapper
        band = WHOOPMapper.recovery_to_readiness_band(self.recovery_score)
        return band.value


@dataclass
class WHOOPStrain:
    """WHOOP strain data"""
    date: datetime
    day_strain: float     # 0-21 scale
    workout_strain: float  # 0-21 scale
    calories: int
    avg_hr: int
    max_hr: int


@dataclass
class WHOOPSleep:
    """WHOOP sleep data"""
    date: datetime
    total_sleep_hours: float
    sleep_efficiency: float  # 0-100
    time_in_bed_hours: float
    slow_wave_sleep_minutes: int
    rem_sleep_minutes: int
    light_sleep_minutes: int
    awake_minutes: int
```

---

## Configuration

### File: `whoop_config.py`

```python
"""WHOOP integration configuration."""

import os
from dataclasses import dataclass


@dataclass
class WHOOPConfig:
    """WHOOP API configuration"""

    # OAuth credentials
    client_id: str
    client_secret: str
    redirect_uri: str

    # API settings
    api_base_url: str = "https://api.whoop.com/v1"
    rate_limit_per_minute: int = 100

    # Caching
    cache_ttl_seconds: int = 14400  # 4 hours

    @classmethod
    def from_env(cls) -> "WHOOPConfig":
        """Load config from environment variables"""
        return cls(
            client_id=os.getenv("WHOOP_CLIENT_ID", ""),
            client_secret=os.getenv("WHOOP_CLIENT_SECRET", ""),
            redirect_uri=os.getenv("WHOOP_REDIRECT_URI", ""),
        )
```

---

## Database Schema

### New Table: `whoop_recovery`

```sql
CREATE TABLE whoop_recovery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID REFERENCES athletes(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    recovery_score DECIMAL(5,2) NOT NULL,  -- 0-100
    hrv_rmssd DECIMAL(6,2),                -- HRV in ms
    resting_hr INTEGER,
    hrv_baseline DECIMAL(6,2),
    sleep_performance DECIMAL(5,2),        -- 0-100
    readiness_band TEXT CHECK (readiness_band IN ('green', 'yellow', 'red')),
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(athlete_id, date)
);

CREATE INDEX idx_whoop_recovery_athlete_date ON whoop_recovery(athlete_id, date DESC);
```

### New Table: `whoop_credentials`

```sql
CREATE TABLE whoop_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID REFERENCES athletes(id) ON DELETE CASCADE UNIQUE,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## API Endpoints (Supabase Edge Functions)

### 1. OAuth Callback Handler

**Endpoint:** `/whoop/oauth/callback`
**Method:** GET
**Purpose:** Handle WHOOP OAuth redirect

### 2. Sync Recovery Data

**Endpoint:** `/whoop/sync/recovery`
**Method:** POST
**Purpose:** Manually trigger recovery data sync

### 3. Get Current Readiness

**Endpoint:** `/whoop/readiness/:athlete_id`
**Method:** GET
**Purpose:** Get today's readiness band for an athlete

---

## Testing Checklist

- [ ] OAuth flow completes successfully
- [ ] Recovery data syncs correctly
- [ ] Recovery score → readiness band mapping is accurate
- [ ] HRV baseline calculation works
- [ ] Session auto-adjustment calculates correctly
- [ ] Rate limiting is respected
- [ ] Error handling for API failures
- [ ] Caching reduces API calls

---

## Deployment Steps

1. Create `z09_integration/whoop/` directory in Quiver
2. Implement WHOOP client, mapper, models
3. Create Supabase migrations for tables
4. Deploy Edge Functions for OAuth + sync
5. Add environment variables to Supabase
6. Test OAuth flow end-to-end
7. Test recovery sync
8. Document for iOS team

---

## Next Step: iOS Integration (ACP-466, ACP-470)

Once Quiver WHOOP client is complete, iOS team can:
1. Implement OAuth flow UI
2. Display WHOOP recovery data
3. Show readiness band in app
4. Implement auto-adjustment UI
