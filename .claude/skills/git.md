# Skill: Git

## When to use
Read git state before reviewing, debugging, or refactoring to understand context.
Only commit when the user explicitly asks.

## Useful reads

| Situation | Command |
|---|---|
| Before a code review | `git diff` — focus on what actually changed |
| Before debugging | `git log --oneline -20` — find what changed before the bug |
| Before refactoring | `git log --oneline -- <file>` — understand file history |
| Check branch state | `git status` / `git branch` |
| Find who changed a line | `git blame <file>` |

## Commit message format

```
IAM-X (type): short description

- file-or-topic: what changed; additional detail after semicolon
- file-or-topic: what changed
  continuation indented two spaces
```

**Subject line**: `IAM-X (type): description`
- Extract the JIRA ticket number from the current branch name (e.g. branch `IAM-7-Add-user-registration` → `IAM-7`)
- Type in parentheses — see table below
- Description: lowercase, imperative mood, no trailing period

**Body** (include when the commit touches multiple files or needs context):
- Blank line between subject and body
- One bullet per file or topic: `- filename: what changed`
- Semicolons separate sub-items on the same bullet; indent continuation lines two spaces

**No `Co-Authored-By` trailer** — never add a co-author line

### Types

| Type | When to use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation, rules, skills, ADRs |
| `chore` | Dependencies, build config, maintenance |
| `config` | Settings, permissions, environment |
| `refactoring` | Code restructuring without behaviour change |
| `init` | First commit of a new module or bounded context |
| `test` | Tests only |

### Examples — subject only

```
IAM-7 (feat): add user registration use case
IAM-7 (fix): correct password hashing in UserFactory
IAM-7 (docs): document aggregate boundary for User and Role
IAM-7 (chore): bump Spring Boot to 3.5.2
IAM-7 (refactoring): extract Email value object from User aggregate
```

### Example — with body

```
IAM-4 (fix): correct security bugs and stale versions in skills

- spring-security: JWT filter now catches ParseException/JOSEException and
  returns 401 instead of propagating 500; loads roles into GrantedAuthority
- testing: update Testcontainers image from postgres:16 to postgres:17
- maven: remove --enable-preview from compiler template
```

## Branch naming

```
IAM-X-Short-Description-In-Title-Case

Examples:
  IAM-7-Add-user-registration
  IAM-8-Fix-jwt-token-expiry
```

## Separating commits

Split changes into multiple commits when they serve different purposes, even if they touch the same feature. A good split lets each commit be understood, reviewed, and reverted independently.

**Split by type** — different `type` labels always go in separate commits:
```
IAM-7 (chore): add spring-boot-starter-data-jdbc dependency   ← pom.xml only
IAM-7 (docs): update rules and skills for Spring Data JDBC    ← .claude/ files
IAM-7 (feat): implement OrderDbEntity and JdbcOrderRepository ← src/ files
```

**Split by concern** — within the same type, separate unrelated changes:
```
IAM-7 (docs): add spring-data-jdbc rule and skill             ← new files
IAM-7 (docs): update agents and commands for Spring Data JDBC ← existing files updated
```

**Keep together** — changes that are only meaningful as a unit belong in one commit:
```
IAM-7 (feat): add Email value object with validation          ← Email.java + test
```

**How to stage selectively** — use `git add <specific files>` rather than `git add .` to control what goes into each commit.

## Rules
- Never commit to `main` or `develop` directly
- One logical change per commit — split by type or concern when in doubt
- Never include `.env`, build output, or generated files
- Never add `Co-Authored-By` trailers