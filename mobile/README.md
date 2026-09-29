# DART CRM Flutter V2

This is the cleaned/migrated copy of the supplied Flutter CRM application. The original ZIP is not modified.

The goal of this version is to keep the existing CRM UI while moving networking and business flows to **CRM Backend V2**.

## Demo account

Email: field@crm.local
Password: Password@123

## Backend configuration

Default API URL is suitable for the standard Android emulator:

## Authentication flow

`CrmApiClient` handles the V2 flow:

```text
Flutter
  -> create/reuse shared x-api-token
  -> user login
  -> JWT access token + refresh token
  -> authenticated CRM APIs
```

Tokens are stored with `flutter_secure_storage`. Dio automatically adds `x-api-token` and the JWT, refreshes an expired user access token and retries one failed request.

The service account defaults in source are dummy local-development values only. Do not ship real production secrets inside a mobile binary.

## Migrated features

- Login/logout/password/session handling.
- Shared API token + JWT/refresh flow.
- Hierarchy/profile/setup compatibility.
- Customer list/search/details/create/update/delete-request flow.
- Customer contacts.
- Geography and customer master data.
- Check-In / Check-Out and location submission.
- Plan list.
- DSR preparation and Visit Entry.
- Server-driven allowed Visit date ranges.
- Follow-ups and joint visit.
- Visit document upload/details.
- Catalog / Sampling Details / Shipment Mode / ShipTo.
- Customer Sampling request.
- Self Stock request.
- Customer Sampling and Self Stock approval screens using the V2 generic multi-level approval engine.
- Quantity approval/rejection/bulk actions.
- Notifications.

## E-Product support

The existing E-Product UI is now connected for the API information supplied:

- DSR parses `SalesStage`, `Brand`, `Prospect`, `ApplicationSetupKeyValue`, `AcademicSession` and multiple `AllowedDateRange` values.
- `VisitBooksSampling` controls the book-sampling section.
- `VisitEProducts` controls the E-Product section.
- Brand selection loads products from Backend V2.
- Product selection loads product details, available Classes and Previous Sales Stage.
- E-Product Visit rows preserve Brand, Product, Sales Stage, Prospect, selected Classes and Remarks.
- Multiple E-Products are submitted inside the **same Visit**, avoiding the old duplicate-Visit behavior.
- The legacy `EProductPromotionDetailsXML` shape is converted to clean V2 JSON by the compatibility/network layer.

## Legacy compatibility layer

Many existing screens were written around endpoint names such as:

```text
CustomerCreationAPI
CustomerListAPI
ApiVisitEntry
CustomerSampling
SelfstockApprovalList
...
```

`lib/core/api/legacy_api_adapter.dart` maps these old screen contracts to V2 REST endpoints. This keeps the existing UI/models while allowing the backend to remain clean.

No old `demo.dartcrm.net` API URL is used by this V2 project.

## UI intentionally kept for later

A few original UI fragments do not yet have enough source-backed API/business rules. They are retained instead of deleted, but no new fake backend contract was invented for them. Current examples include:

- optional Enrollment panel in customer editing;
- optional School Facility panel;
- some Notes/Comments/extra customer UI fields;
- menu destinations for which the supplied Flutter project itself has no implemented screen.

When those APIs/rules are supplied, they can be connected separately.

## Run locally

First run CRM Backend V2 and import its fresh MySQL schema/seed. Then:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Standard Android emulator:

```bash
flutter run --dart-define=CRM_API_BASE_URL=http://10.0.2.2:5000/api
```

Physical phone (example):

```bash
flutter run --dart-define=CRM_API_BASE_URL=http://192.168.1.10:5000/api
```

The phone and development computer must be able to reach each other on the network and the Node.js port must be allowed by the firewall.

## Demo login

With `database/seed.sql` imported:

```text
field@crm.local
Password@123
```

Manager accounts are available in the backend README for testing the full L1 -> L2 -> ... approval chain.

## Validation note

The packaging environment used to migrate this project does not contain the Flutter/Dart SDK, so `flutter analyze` and an APK build cannot be truthfully certified here. Source-level checks are included/performed for imports, delimiter balance, endpoint mapping and stale old-host references. The final authoritative validation is to run the four Flutter commands above on your machine.
