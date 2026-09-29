# CRM backend - Deployment / Validation Notes

## Current package

Version reported by `/health`: `3.0-approval-workflow`.

This package includes all V2.3 fixes plus the V3 configurable approval workflow. See `APPROVAL_WORKFLOW_V3.md` for business behavior and `UPGRADE_TO_V3.md` for the existing-database upgrade path.

## Existing database

If the database is already on V2.3, do **not** rerun `schema.sql` or `seed.sql`. Back it up and run only:

```text
database/migrations/003_approval_workflow_v3.sql
```

once.

## Source validation performed in the packaging environment

- JavaScript syntax checker passed for all backend source files covered by `npm run check`.
- Postman collection JSON validates syntactically and includes V3 approval/admin examples.
- Full Node test execution could not be certified in the packaging environment because dependencies are not installed there (`mysql2` is unavailable until `npm install`). Run `npm install && npm test` locally.
- A live MySQL V3 migration/integration run must be performed against a backup/staging copy before production deployment.

## Production checklist

- Set `NODE_ENV=production`.
- Use a long random `JWT_ACCESS_SECRET`.
- Rotate any credentials that have been exposed during development.
- Restrict `CORS_ORIGINS` to deployed application origins where applicable.
- Deploy behind HTTPS / TLS.
- Do not commit `.env`.
- Use a non-root least-privilege MySQL user.
- Back up MySQL before running migration 003.
- Run `npm install`, `npm test`, and smoke tests for login, menus, each approval module, admin role toggling, final approval, forwarding, rejection, and quantity changes.
