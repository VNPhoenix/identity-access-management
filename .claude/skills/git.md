# Skill: Git

## When to use
Read git state before reviewing, debugging, or refactoring to understand context.
Git is read-only — never commit, push, or modify history on behalf of the user.

## Useful reads

| Situation | Command |
|---|---|
| Before a code review | `git diff` — focus on what actually changed |
| Before debugging | `git log --oneline -20` — find what changed before the bug |
| Before refactoring | `git log --oneline -- <file>` — understand file history |
| Check branch state | `git status` / `git branch` |
| Find who changed a line | `git blame <file>` |

## Commit message convention
All commits follow Conventional Commits:

```
type(scope): short description

Types:  feat | fix | refactor | test | docs | chore
Scope:  bounded context or module (orders, customers, payments)

Examples:
  feat(orders): add place order use case
  fix(orders): correct total calculation in OrderLine
  refactor(customers): extract Email value object
  test(orders): add Testcontainers repository integration test
  chore(deps): bump Spring Boot to 3.5.1
  docs(orders): document aggregate boundary decisions
```

## Branch naming
```
feature/{scope}-{short-description}   → feature/orders-place-order
fix/{scope}-{short-description}       → fix/orders-total-calculation
chore/{description}                   → chore/bump-spring-boot
```

## Rules
- Never commit to `main` or `develop` directly
- One logical change per commit
- Never include `.env`, build output, or generated files
- When suggesting a commit message, always follow the convention above
