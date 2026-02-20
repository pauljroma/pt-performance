# Push Supabase migrations safely

Applies pending database migrations to the remote Supabase project.

## Arguments
- `$ARGUMENTS`: Optional migration filename to target (default: all pending)

## Safety Checks

1. List recent migrations:
```bash
ls -1 /Users/expo/pt-performance/supabase/migrations/ | tail -10
```

2. Review the SQL before pushing. Verify:
   - INSERTs use `ON CONFLICT DO NOTHING` or `ON CONFLICT DO UPDATE`
   - RLS is never disabled
   - Functions use `CREATE OR REPLACE`
   - No unguarded `DROP TABLE`

## Push

```bash
cd /Users/expo/pt-performance
source /Users/expo/Code/expo/clients/linear-bootstrap/.env
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

Answer `Y` when prompted. If migration history conflict, add `--repair` flag.

## Verify

Dry-run should show no pending migrations:
```bash
supabase db push -p "${SUPABASE_PASSWORD}" --include-all --dry-run
```

New migration files use format: `YYYYMMDDHHMMSS_description.sql`
Template: `.claude/migration_template.sql`
