# Command: /new-migration

Generate a Flyway SQL migration for: $ARGUMENTS

## Rules to follow
- `.claude/rules/infrastructure-layer.md`
- `.claude/rules/jdbc.md`
- `.claude/rules/never-do.md`

## Skills to use
- `.claude/skills/spring-jdbc.md`
- `.claude/skills/maven.md`

## Steps

1. Scan `src/main/resources/db/migration/` to find the highest existing version number.
   Next version = highest + 1.

2. Create `src/main/resources/db/migration/V{next}__{snake_case_description}.sql`

3. Write the migration SQL following these conventions:

   New table (UUID primary key):
   ```sql
   CREATE TABLE IF NOT EXISTS {table_name} (
       id          UUID                                PRIMARY KEY,
       -- domain columns here
       created_at  TIMESTAMPTZ NOT NULL                DEFAULT NOW(),
       updated_at  TIMESTAMPTZ NOT NULL                DEFAULT NOW()
   );
   ```

   New table (Long primary key — DB-assigned):
   ```sql
   CREATE TABLE IF NOT EXISTS {table_name} (
       id          BIGINT GENERATED ALWAYS AS IDENTITY  PRIMARY KEY,
       -- domain columns here
       created_at  TIMESTAMPTZ NOT NULL                 DEFAULT NOW(),
       updated_at  TIMESTAMPTZ NOT NULL                 DEFAULT NOW()
   );
   ```

   New column:
   ```sql
   ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {column} {type};
   ```

   New index:
   ```sql
   CREATE INDEX IF NOT EXISTS idx_{table}_{column} ON {table}({column});
   ```

   - UUID columns: `UUID` type in PostgreSQL
   - Long PK columns: `BIGINT GENERATED ALWAYS AS IDENTITY` — never `SERIAL` or manual sequences
   - Timestamps: `TIMESTAMPTZ` — always UTC
   - Enums stored as strings: `VARCHAR(50) NOT NULL`
   - Money/decimals: `NUMERIC(19,4)`
   - All migrations idempotent: use `IF NOT EXISTS` / `IF EXISTS`

4. Add a rollback block as a comment at the top:
   ```sql
   -- Rollback: DROP TABLE IF EXISTS {table_name};
   ```

5. Verify the `{Aggregate}ResultSetExtractor` column references still match
   after this migration. Note any columns that need updating.

6. Run `mvn flyway:migrate` to apply and validate.

## Output
Full path of the migration file created and a summary of changes.
