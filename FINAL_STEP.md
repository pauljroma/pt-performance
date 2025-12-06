# Final Step - Deploy RM Estimate Column

## ✅ Already Deployed
- agent_logs table ✅

## ⏳ One More Migration Needed
- rm_estimate column (1 minute)

## 🚀 Quick Steps

1. **Open Supabase SQL Editor:**
   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql

2. **Click "New Query"**

3. **Copy the SQL below** (or open `infra/005_add_rm_estimate.sql`)

4. **Paste and Click "Run"**

5. **Run verification:**
   ```bash
   python3 verify_migrations.py
   ```

6. **Mark everything Done in Linear:**
   ```bash
   python3 complete_mvp_in_linear.py
   ```

---

## SQL to Copy/Paste

```sql
-- Add rm_estimate column to exercise_logs
ALTER TABLE exercise_logs
ADD COLUMN IF NOT EXISTS rm_estimate DECIMAL(10,2);

-- Create calculation function
CREATE OR REPLACE FUNCTION calculate_rm_estimate(weight DECIMAL, reps INT)
RETURNS DECIMAL AS $$
BEGIN
    IF weight IS NULL OR weight <= 0 OR reps IS NULL OR reps <= 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(weight * (1 + reps / 30.0), 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger function
CREATE OR REPLACE FUNCTION update_rm_estimate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.actual_load IS NOT NULL AND NEW.actual_load > 0 THEN
        IF NEW.actual_reps IS NOT NULL THEN
            IF pg_typeof(NEW.actual_reps) = 'integer'::regtype THEN
                NEW.rm_estimate = calculate_rm_estimate(NEW.actual_load, NEW.actual_reps);
            ELSIF pg_typeof(NEW.actual_reps) = 'jsonb'::regtype THEN
                NEW.rm_estimate = calculate_rm_estimate(NEW.actual_load, (NEW.actual_reps->0)::int);
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS exercise_logs_rm_estimate ON exercise_logs;
CREATE TRIGGER exercise_logs_rm_estimate
BEFORE INSERT OR UPDATE ON exercise_logs
FOR EACH ROW EXECUTE FUNCTION update_rm_estimate();

-- Backfill existing logs
UPDATE exercise_logs
SET rm_estimate = calculate_rm_estimate(
    actual_load,
    CASE
        WHEN pg_typeof(actual_reps) = 'integer'::regtype THEN actual_reps
        WHEN pg_typeof(actual_reps) = 'jsonb'::regtype THEN (actual_reps->0)::int
        ELSE NULL
    END
)
WHERE actual_load IS NOT NULL
  AND actual_load > 0
  AND actual_reps IS NOT NULL
  AND rm_estimate IS NULL;

-- Create index
CREATE INDEX IF NOT EXISTS idx_exercise_logs_rm_estimate
ON exercise_logs(patient_id, rm_estimate DESC)
WHERE rm_estimate IS NOT NULL;

-- Create view
CREATE OR REPLACE VIEW vw_rm_progression AS
SELECT
    el.patient_id,
    se.exercise_template_id,
    et.exercise_name,
    DATE(el.logged_at) as log_date,
    el.actual_load,
    el.actual_reps,
    el.rm_estimate,
    MAX(el.rm_estimate) OVER (
        PARTITION BY el.patient_id, se.exercise_template_id
        ORDER BY el.logged_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as max_rm_to_date
FROM exercise_logs el
JOIN session_exercises se ON el.session_exercise_id = se.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
WHERE el.rm_estimate IS NOT NULL
ORDER BY el.patient_id, et.exercise_name, el.logged_at DESC;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ rm_estimate column and trigger deployed successfully!';
END $$;
```

---

That's it! Once you paste and run this, we're 100% done! 🎉
