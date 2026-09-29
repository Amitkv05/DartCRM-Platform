# Upgrade Existing CRM V2.3 Database to V3

1. Back up the existing MySQL database.
2. Keep the same database and business data.
3. Run `database/migrations/003_approval_workflow_v3.sql` **once**.
4. Replace the backend source with the V3 package.
5. Copy your existing `.env` into the V3 backend folder.
6. Run `npm install` and `npm run dev`.
7. Verify `GET /health` reports `3.0-approval-workflow`.
8. Replace the Flutter source with the matching V3 package.
9. Keep the correct API URL in `lib/core/config/app_config.dart`.
10. Run `flutter clean`, `flutter pub get`, `flutter analyze`, then `flutter run`.
11. Log out and log in again so the app reloads server-driven menus.

Do not run `schema.sql` or `seed.sql` against your existing database during this upgrade.
