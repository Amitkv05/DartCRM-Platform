# Upgrade CRM V3 to V4 Admin & Audit

1. Back up the existing CRM V3 database.
2. Run `database/migrations/004_admin_role_audit_v4.sql` ONCE.
3. Do not rerun `schema.sql` or `seed.sql` on an existing database.
4. Copy your existing `.env` into this backend folder.
5. Run `npm install`, `npm run check`, `npm test`, then `npm run dev`.
6. Confirm `GET /health` reports version `4.0-admin-audit`.
7. Use the V4 Flutter project, run `flutter clean`, `flutter pub get`, `flutter analyze`, then `flutter run`.
8. Log out and log in again so the new Admin and Request History menus are loaded.

V4 adds full Admin user/role management, custom menu access, admin audit history, requester history, and global visibility for finalized/validated customers.
