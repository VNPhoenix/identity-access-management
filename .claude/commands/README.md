# Commands

Slash commands for Claude Code. Each file is one reusable command.
Invoke with `/command-name` (no arguments) or `/command-name some description`
for commands that accept `$ARGUMENTS`.

---

## Index

| File | Invoke | Takes args | Purpose |
|---|---|---|---|
| `new-feature.md` | `/new-feature` | yes | Full vertical slice — all layers end to end |
| `new-aggregate.md` | `/new-aggregate` | yes | Domain layer — aggregate, value objects, events, repository interface |
| `new-use-case.md` | `/new-use-case` | yes | Application layer — use case, command/query objects |
| `new-repository.md` | `/new-repository` | yes | Infrastructure layer — Spring Data JDBC repository + type converters |
| `new-migration.md` | `/new-migration` | yes | Flyway SQL migration file |
| `add-endpoint.md` | `/add-endpoint` | yes | Add one REST endpoint wired to a new use case |
| `write-tests.md` | `/write-tests` | no | Full test suite for the current file |
| `add-test-case.md` | `/add-test-case` | yes | Add one missing test case to the current test file |
| `review.md` | `/review` | no | DDD + Spring correctness review of the current file |
| `security-audit.md` | `/security-audit` | no | Security vulnerability audit of the current file |
| `performance-review.md` | `/performance-review` | no | JDBC and API performance audit of the current file |
| `refactor.md` | `/refactor` | yes | Structural refactoring toward correct DDD |
| `debug.md` | `/debug` | yes | Diagnose and fix a described runtime issue |
| `explain.md` | `/explain` | no | Explain the current file to a new developer |

---

## Usage examples

```
/new-feature Order with lines and total calculation
/new-aggregate Product with name, price, and stock quantity
/new-use-case Place order for the Order aggregate
/new-repository Order
/new-migration add shipped_at column to orders
/add-endpoint GET /api/v1/orders/{id}/lines for the Order resource
/write-tests
/add-test-case placing an order with no lines throws an exception
/review
/security-audit
/performance-review
/refactor extract Email value object from Customer
/debug @Transactional not rolling back in PlaceOrderUseCase
/explain
```

---

## Agents

For heavier tasks that would pollute the main conversation context, use an agent
from `.claude/agents/` instead of (or after) the equivalent command:

| Agent | When to prefer over the command |
|---|---|
| `ddd-reviewer` | Reviewing multiple files or a full PR — reads all 13 rules in isolation |
| `iam-security-auditor` | Pre-merge security review — 30+ IAM-specific checks |
| `test-writer` | Writing + running tests — keeps test output out of main context |
| `migration-validator` | Validating SQL before apply — returns APPROVED / NEEDS FIXES verdict |
| `feature-scaffolder` | Full vertical slice — generates all layers and compiles autonomously |

---

## Command dependencies

Every command references the rules and skills it depends on at the top of the file.
Claude reads those files before executing the command.

```
command → rules (what to enforce)
       → skills (how to write the code)
       → maven  (verify the result compiles and tests pass)
```
