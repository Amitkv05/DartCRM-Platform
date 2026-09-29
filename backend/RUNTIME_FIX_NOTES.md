# CRM backend - Runtime Fix Update

Use this package together with the matching `dart_crm_v2_runtime_fixed.zip` Flutter project.

## Why this update is required

The first V2 backend package expected `samplingTypeId` in Customer Sampling. The migrated Flutter UI sends the original CRM sampling type name such as `Personal Copy`. That mismatch could pass `undefined` into mysql2 and produce:

`Bind parameters must not contain undefined. To pass SQL NULL specify JS null`

This build resolves sampling types by ID **or name**, validates all important references, prevents undefined SQL bind values, includes the real Visit document-upload endpoint, and includes the later E-Product/Visit schema and APIs.

## Upgrade an existing first-V2 database

Do **not** rerun the complete schema/seed over an existing database that you want to keep.

1. Back up the database.
2. Select your existing CRM V2 database in phpMyAdmin/MySQL.
3. Run `database/migrations/001_upgrade_previous_v2.sql` once.
4. Replace the old backend source with this package.
5. Copy your own `.env` into the new backend folder. Do not copy `.env` into source control.
6. Run `npm install`.
7. Run `npm run dev`.
8. Open `http://localhost:5000/health`.

The correct updated build reports:

```json
{
  "status": "success",
  "service": "crm-backend-v2",
  "version": "2.1-runtime-fix",
  "features": ["file-upload", "e-products", "sampling-name-compat"]
}
```

## Runtime fixes in this build

- Customer Sampling accepts `samplingTypeName` and never passes JavaScript `undefined` as a SQL bind parameter.
- Approval creation validates the derived first approver/profile level.
- `POST /api/files/upload` stores Visit PDF/JPG/JPEG/PNG files up to 10 MB.
- `/uploads/...` is served by Express so Visit Details can reopen stored documents.
- E-Product masters and Visit promotion support are included.
- DSR allowed-date-range support is included.
- Backend listens on `0.0.0.0` for Android physical-device testing on the same LAN.
- Flutter-compatible HomeScreen menu seed is included in the database upgrade migration.
