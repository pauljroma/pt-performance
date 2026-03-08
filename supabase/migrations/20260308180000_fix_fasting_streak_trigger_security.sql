-- Fix: Make update_fasting_streak() SECURITY DEFINER so the trigger can
-- INSERT/UPDATE fasting_streaks regardless of calling user's RLS context.
-- Without this, ending a fast fails because fasting_streaks RLS only checks
-- patient_id = auth.uid(), which doesn't match when patient record ID differs
-- from the auth user ID.

CREATE OR REPLACE FUNCTION update_fasting_streak()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak_record fasting_streaks%ROWTYPE;
    v_fast_date DATE;
    v_days_since_last INTEGER;
BEGIN
    -- Only process when a fast is completed (ended_at changes from NULL to NOT NULL)
    IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL AND NEW.was_broken_early = FALSE THEN
        v_fast_date := DATE(NEW.ended_at);

        -- Get or create streak record
        SELECT * INTO v_streak_record
        FROM fasting_streaks
        WHERE patient_id = NEW.patient_id;

        IF NOT FOUND THEN
            -- Create new streak record
            INSERT INTO fasting_streaks (
                patient_id,
                current_streak,
                longest_streak,
                last_fast_date,
                streak_start_date,
                total_fasts_completed,
                total_hours_fasted
            ) VALUES (
                NEW.patient_id,
                1,
                1,
                v_fast_date,
                v_fast_date,
                1,
                COALESCE(NEW.actual_hours, 0)
            );
        ELSE
            -- Calculate days since last fast
            IF v_streak_record.last_fast_date IS NOT NULL THEN
                v_days_since_last := v_fast_date - v_streak_record.last_fast_date;
            ELSE
                v_days_since_last := 999;
            END IF;

            IF v_days_since_last <= 2 THEN
                -- Continue streak (allow 1 day gap)
                UPDATE fasting_streaks SET
                    current_streak = current_streak + 1,
                    longest_streak = GREATEST(longest_streak, current_streak + 1),
                    last_fast_date = v_fast_date,
                    total_fasts_completed = total_fasts_completed + 1,
                    total_hours_fasted = total_hours_fasted + COALESCE(NEW.actual_hours, 0),
                    updated_at = NOW()
                WHERE patient_id = NEW.patient_id;
            ELSE
                -- Reset streak
                UPDATE fasting_streaks SET
                    current_streak = 1,
                    longest_streak = GREATEST(longest_streak, 1),
                    last_fast_date = v_fast_date,
                    streak_start_date = v_fast_date,
                    total_fasts_completed = total_fasts_completed + 1,
                    total_hours_fasted = total_hours_fasted + COALESCE(NEW.actual_hours, 0),
                    updated_at = NOW()
                WHERE patient_id = NEW.patient_id;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
