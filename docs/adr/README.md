# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the IAM service.

An ADR captures a significant architectural decision — its context, the choice made,
the alternatives considered, and the expected consequences. Once accepted, an ADR is
immutable. To revise a decision, a new ADR is written that supersedes the old one.

See [Martin Fowler's introduction to ADRs](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html)
for background on the format and rationale.

---

## Versioning convention

| Format | Meaning |
|---|---|
| `1.0`, `1.1`, … | First decision area and its revisions |
| `2.0`, `2.1`, … | Second independent decision area |
| Superseded ADRs | Kept in place; marked `Superseded` with a link to the successor |

File pattern: `ADR-{version}-{kebab-case-title}.md`

---

## Index

| Version | Title | Status | Date |
|---|---|---|---|
| [1.0](ADR-1.0-dockerize-with-layertools.md) | Dockerizing the IAM Service with Spring Boot Layertools | Accepted | 2026-05-15 |
