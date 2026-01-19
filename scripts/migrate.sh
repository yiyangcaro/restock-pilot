#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-restock_pilot}"
DB_USER="${DB_USER:-rp}"
DB_PASSWORD="${DB_PASSWORD:-rp}"

export PGPASSWORD="$DB_PASSWORD"

psql_base=(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1)

# Ensure migrations table exists (in public)
"${psql_base[@]}" << 'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
SQL

for f in scripts/migrations/*.sql; do
  v="$(basename "$f")"
  applied="$("${psql_base[@]}" -Atc "SELECT 1 FROM schema_migrations WHERE version = '$v' LIMIT 1;")"
  if [[ "$applied" == "1" ]]; then
    echo "SKIP  $v"
  else
    echo "APPLY $v"
    "${psql_base[@]}" -f "$f"
    "${psql_base[@]}" -c "INSERT INTO schema_migrations(version) VALUES ('$v');"
  fi
done

echo "Done."
