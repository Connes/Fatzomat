# Release und Rollback

## Ablauf

```text
Branch -> CI -> Staging -> E2E -> Release Candidate -> Human Approval -> Production
```

## Rollback

Code-Rollback ist grundsätzlich über Git möglich. Datenbank-Rollback muss für jede potenziell destruktive Migration separat geplant werden; PostgreSQL-Migrationen sind nicht automatisch reversibel.

Vor Production müssen Recovery-/Rollback-Schritte in Staging erprobt werden.
