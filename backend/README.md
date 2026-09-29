# CRM backend - Admin & Audit

**Current release: 4.0-admin-audit**

V4 adds full Admin user/role management, custom menu access, requester request-history, central Admin approval/audit history, and finalized customer visibility across all CRM levels. For an existing V3 database, run only `database/migrations/004_admin_role_audit_v4.sql` once.

See `UPGRADE_TO_V4.md` and `ADMIN_ROLE_AND_AUDIT_V4.md`.

# CRM backend

> **Current package: V3.0 approval workflow.** Existing V2.3 databases must run `database/migrations/003_approval_workflow_v3.sql` once. See `UPGRADE_TO_V3.md` and `APPROVAL_WORKFLOW_V3.md`.

V3 adds Customer Update approvals, manager approval eligibility, admin-only approval-role management, manager skipping, final-vs-next-level approval, module-specific manager review pages, and editable Sampling/Self-Stock quantities. L1 is request-only.

A clean Node.js + Express + MySQL rebuild of the CRM business workflow documented in the supplied API references. The old backend/database are not required by this project.

## What this V2 implements

- One shared **application/service API token** created from a service-account email + secret.
- Separate CRM user login with JWT access token + refresh token.
- User / Executive / Profile separation.
- `UpHierarchy` and `DownHierarchy` calculated from `executives.manager_executive_id`.
- Profile menus, territory/city access, product divisions and setup values.
- Customer creation, update, list/search, master data, details and delete-request workflow.
- Customer contacts with setup-driven validation and approval for non-directly-validated profiles.
- Check-In / Check-Out and executive GPS location tracking.
- Plan list, DSR preparation data, follow-up executive lookup and Visit Entry.
- Visit documents, joint executives, follow-ups and optional Customer Sampling inside the same DB transaction.
- Visit backdate request approval.
- Series, class levels, titles, standalone title search and shipment modes.
- Sampling Details -> ShipTo -> Customer Sampling request.
- Sampling budget snapshot/check.
- Self Stock preparation -> Trade address -> request.
- Generic reusable multi-level approval engine for:
  - Customer creation
  - Customer update (staged until final approval)
  - Contact creation
  - Customer deletion
  - Visit backdate request
  - Customer Sampling
  - Self Stock
- Quantity-level approval history for Sampling and Self Stock.
- Bulk approval/rejection.
- Notifications when approval ownership changes or the request reaches a final state.
- Separate request / approval / shipment statuses.

## Important design choice

The original reference demonstrates that requests can move from `Pending for Level 2` to another level after approval, but it does not define one universal hard-coded profile-to-level map for every module.

This V2 therefore uses the executive reporting hierarchy:

```text
Requester
   -> Requester's manager
   -> Manager's manager
   -> ...
   -> Top executive
   -> Final Approved
```

A rejection at any current approval level ends the workflow immediately. V3 also allows an approver to either final-approve at the current level or approve-and-forward to the next eligible approval-enabled manager. Managers with approval disabled are skipped automatically.

## Requirements

- Node.js 20+
- MySQL 8+ (or a compatible recent MariaDB version)

## Installation

```bash
npm install
cp .env.example .env
```

Edit `.env` with your MySQL credentials.

Create and seed the database:

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
```

If your hosted MySQL account cannot run `CREATE DATABASE`, create a database named `crm_dummy_v2` manually and remove the first `CREATE DATABASE` statement from `database/schema.sql`.

Run:

```bash
npm run dev
```

Health check:

```text
GET /health
```

## Demo credentials

### Application/service account

Used only to create the shared API token:

```text
Email:  crm-service@example.com
Secret: crm-service-secret
```

### CRM users

All seeded CRM users use:

```text
Password: Password@123
```

Accounts:

```text
field@crm.local      L1 -> reports to L2
manager@crm.local    L2 -> reports to L3
regional@crm.local   L3 -> reports to L4
zonal@crm.local      L4 -> reports to L5
national@crm.local   L5 -> reports to HDA
admin@crm.local      HDA -> top of hierarchy
```

The bootstrap seed uses a portable `sha256$...` password hash. The Change Password / Reset Password endpoints store new passwords with bcrypt.

---

# Authentication flow

## 1. Generate shared API token

```http
POST /api/token
Content-Type: application/json

{
  "email": "crm-service@example.com",
  "secret": "crm-service-secret"
}
```

Response contains `apiToken`.

Every API after this (including CRM user login) requires:

```http
x-api-token: <apiToken>
```

## 2. Login CRM user

```http
POST /api/auth/login
x-api-token: <apiToken>
Content-Type: application/json

{
  "email": "field@crm.local",
  "password": "Password@123"
}
```

The response returns:

- JWT `accessToken`
- `refreshToken`
- UserId / ExecutiveId
- ProfileId / ProfileCode
- UpHierarchy
- DownHierarchy
- TerritoryAccess
- CityAccess
- ProductDivision
- ApplicationSetup

Protected user APIs require both headers:

```http
x-api-token: <apiToken>
Authorization: Bearer <accessToken>
```

---

# Main workflow map

```text
SERVICE ACCOUNT
   -> shared x-api-token

CRM USER LOGIN
   -> User / Executive / Profile
   -> UpHierarchy / DownHierarchy
   -> Access / Setup values

FIELD WORK
   -> Check In
   -> Plan
   -> Customer
   -> DSR preparation
   -> Visit Entry
      -> Joint Visit
      -> Documents
      -> Follow-up
      -> optional Customer Sampling
   -> Location updates
   -> Check Out

CUSTOMER SAMPLING
   -> Sampling Details
   -> ShipTo
   -> Shipment Mode
   -> Customer Sampling Request
   -> Approval Inbox
   -> Approval Details
   -> Manager approves quantities / rejects
   -> Next manager
   -> Final approval
   -> Shipment stage is separate

SELF STOCK
   -> Self Stock master data
   -> optional Trade shipping address
   -> Self Stock Request
   -> Approval Inbox
   -> Approval Details
   -> Multi-level approval
   -> Shipment stage is separate
```

---

# API endpoints

## API token + auth

| Method | Endpoint                    | Purpose                             |
| ------ | --------------------------- | ----------------------------------- |
| POST   | `/api/token`                | Create shared application API token |
| POST   | `/api/auth/login`           | CRM user login                      |
| POST   | `/api/auth/refresh`         | Refresh user access token           |
| POST   | `/api/auth/logout`          | Revoke refresh token                |
| POST   | `/api/auth/forgot-password` | Create password-reset token         |
| POST   | `/api/auth/reset-password`  | Reset password                      |
| POST   | `/api/auth/change-password` | Change logged-in user's password    |

## Executive / setup / access

| Method | Endpoint                         | Purpose                                 |
| ------ | -------------------------------- | --------------------------------------- |
| GET    | `/api/executives/me/hierarchy`   | Up + down hierarchy                     |
| GET    | `/api/executives/down-hierarchy` | Executives visible below current user   |
| GET    | `/api/executives/:id`            | Executive details                       |
| GET    | `/api/menus`                     | Menu list for current profile           |
| GET    | `/api/setup`                     | All active setup values                 |
| GET    | `/api/setup?key=VisitEntryDays`  | One setup value                         |
| GET    | `/api/geography`                 | Country/state/district/city master data |

## Attendance / field location

| Method | Endpoint                    | Purpose                      |
| ------ | --------------------------- | ---------------------------- |
| POST   | `/api/attendance/check-in`  | Check in with GPS            |
| POST   | `/api/attendance/check-out` | Check out with GPS           |
| GET    | `/api/attendance/today`     | Current day's attendance     |
| POST   | `/api/attendance/locations` | Submit executive GPS entries |

## Plans / Visit / DSR

| Method | Endpoint                                          | Purpose                                                              |
| ------ | ------------------------------------------------- | -------------------------------------------------------------------- |
| GET    | `/api/plans`                                      | Today / tomorrow / travel plan                                       |
| POST   | `/api/plans`                                      | Create a plan item                                                   |
| GET    | `/api/visits/dsr-entry?customerId=1`              | Customer summary + VisitPurpose + JoinVisit + PersonMet + Department |
| GET    | `/api/visits/follow-up-executives?departmentId=1` | Executives for follow-up assignment                                  |
| POST   | `/api/visits/backdate-requests`                   | Request approval for an older visit date                             |
| POST   | `/api/visits`                                     | Create visit + child data in one transaction                         |
| GET    | `/api/visits/details?visitId=1`                   | Visit details                                                        |
| GET    | `/api/visits/details?customerId=1`                | Customer visit history                                               |

## Customer

| Method | Endpoint                            | Purpose                                     |
| ------ | ----------------------------------- | ------------------------------------------- |
| GET    | `/api/customers/master-data`        | Boards/classes/categories/designations/etc. |
| POST   | `/api/customers`                    | Create customer                             |
| PUT    | `/api/customers/:id`                | Update customer                             |
| GET    | `/api/customers`                    | Customer list                               |
| GET    | `/api/customers/:id`                | Customer details                            |
| GET    | `/api/customers/search`             | Search customers                            |
| GET    | `/api/customers/search-cities`      | Cities available to current executive       |
| GET    | `/api/customers/book-sellers`       | Trade/bookseller search                     |
| POST   | `/api/customers/:id/delete-request` | Submit customer deletion for approval       |

## Contacts

| Method | Endpoint                             | Purpose               |
| ------ | ------------------------------------ | --------------------- |
| GET    | `/api/contacts/customer/:customerId` | Customer contact list |
| POST   | `/api/contacts`                      | Create contact        |
| GET    | `/api/contacts/:id`                  | Contact details       |
| PUT    | `/api/contacts/:id`                  | Update contact        |
| DELETE | `/api/contacts/:id`                  | Soft-delete contact   |

## Catalog / Sampling preparation

| Method | Endpoint                                   | Purpose                                               |
| ------ | ------------------------------------------ | ----------------------------------------------------- |
| GET    | `/api/catalog/series-class-levels`         | Series + class-level list                             |
| GET    | `/api/catalog/titles?seriesId=1`           | Titles in a series                                    |
| GET    | `/api/catalog/titles?bookISBN=English`     | Search title / ISBN                                   |
| GET    | `/api/catalog/titles/search?query=English` | Standalone title search                               |
| GET    | `/api/catalog/shipment-modes`              | Shipment modes                                        |
| GET    | `/api/sampling/details?customerId=1`       | Sampling types, SampleGiven, books, SampleTo contacts |
| GET    | `/api/sampling/ship-to?...`                | Residential/office shipping address                   |

## Customer Sampling

| Method | Endpoint                     | Purpose                          |
| ------ | ---------------------------- | -------------------------------- |
| POST   | `/api/sampling/customer`     | Create Customer Sampling request |
| GET    | `/api/sampling/requests`     | Logged-in executive's requests   |
| GET    | `/api/sampling/requests/:id` | Request + item details           |
| GET    | `/api/sampling/approvals`    | Sampling approval inbox          |

## Self Stock

| Method | Endpoint                          | Purpose                        |
| ------ | --------------------------------- | ------------------------------ |
| GET    | `/api/self-stock/master-data`     | ShipmentMode + ShipTo choices  |
| GET    | `/api/self-stock/trade-addresses` | Trade shipping destinations    |
| POST   | `/api/self-stock/requests`        | Create Self Stock request      |
| GET    | `/api/self-stock/requests`        | Logged-in executive's requests |
| GET    | `/api/self-stock/requests/:id`    | Self Stock request details     |
| GET    | `/api/self-stock/approvals`       | Self Stock approval inbox      |

## Generic approvals

| Method | Endpoint                                  | Purpose                            |
| ------ | ----------------------------------------- | ---------------------------------- |
| GET    | `/api/approvals`                          | Current executive's approval inbox |
| GET    | `/api/approvals?module=CUSTOMER_SAMPLING` | Filter approval inbox              |
| GET    | `/api/approvals/:id`                      | Approval history/details           |
| POST   | `/api/approvals/:id/action`               | Approve/reject current approval    |
| POST   | `/api/approvals/bulk-action`              | Bulk approve/reject                |

Modules currently using the approval engine:

```text
CUSTOMER_CREATE
CONTACT_CREATE
CUSTOMER_DELETE
VISIT_BACKDATE
CUSTOMER_SAMPLING
SELF_STOCK
```

## Notifications

| Method | Endpoint                      | Purpose                           |
| ------ | ----------------------------- | --------------------------------- |
| GET    | `/api/notifications`          | Current executive's notifications |
| PATCH  | `/api/notifications/:id/read` | Mark notification read            |

---

# Multi-level approval example

Seed hierarchy:

```text
Field Executive (L1 / 1001)
  -> Sales Manager (L2 / 1002)
  -> Regional Manager (L3 / 1003)
  -> Zonal Manager (L4 / 1004)
  -> National Manager (L5 / 1005)
  -> CRM Admin (HDA / 1006)
```

If L1 creates a Customer Sampling request:

```text
Create request
  -> approval current approver = L2

L2 approves
  -> quantities saved for level 1
  -> request moves to L3

L3 approves
  -> new quantity decision saved
  -> request moves to L4

...

HDA approves
  -> no higher manager
  -> approval_requests.status = APPROVED
  -> customer_sampling_requests.approval_status = APPROVED
  -> requester notified
```

If any current approver rejects:

```text
PENDING -> REJECTED
```

No higher approver receives it.

## Quantity rules

Single Sampling/Self Stock approval requires an `items` array:

```json
{
  "action": "APPROVE",
  "remarks": "Approved with reduced quantity",
  "items": [
    { "itemId": 1, "approvedQty": 4 },
    { "itemId": 2, "approvedQty": 2 }
  ]
}
```

A later approval level cannot increase a quantity above the quantity approved by the previous level.

Bulk approval can omit item quantities; it keeps the currently approved quantity (or the originally requested quantity on the first level).

---

# Customer Sampling request example

```json
{
  "customerId": 1,
  "customerType": "SCHOOL",
  "executiveId": 1001,
  "shipmentModeId": 1,
  "shippingInstructions": "Call before delivery",
  "requestRemarks": "Teacher review copies",
  "items": [
    {
      "seriesId": 1,
      "bookId": 1,
      "requestedQty": 5,
      "samplingTypeId": 3,
      "sampleToContactId": 2,
      "sampleGiven": "TO_BE_DISPATCHED",
      "shipTo": "OFFICE_ADDRESS",
      "shippingAddress": "Demo Public School, Laxmi Nagar, Delhi"
    }
  ]
}
```

The server generates a number in the form:

```text
CS/MMYY/sequence
```

The original document showed examples such as `CS/0325/1`; the exact original generator was not documented, so this is the V2 implementation choice.

---

# Self Stock request example

```json
{
  "executiveId": 1001,
  "shipTo": "RESIDENCE_ADDRESS",
  "shippingAddress": "Demo residential address",
  "shipmentModeId": 2,
  "remarks": "Demo stock requirement",
  "items": [
    { "subjectId": 1, "seriesId": 1, "bookId": 1, "requestedQty": 4 },
    { "subjectId": 3, "seriesId": 2, "bookId": 3, "requestedQty": 3 }
  ]
}
```

The server generates:

```text
SS/MMYY/sequence
```

---

# Visit Entry example

A visit can create all child objects atomically:

```json
{
  "customerId": 1,
  "customerType": "SCHOOL",
  "customerContactId": 1,
  "visitPurposeId": 3,
  "visitFeedback": "Detailed feedback long enough to satisfy the configured minimum characters.",
  "visitDate": "2026-09-09",
  "address": "Demo Public School, Delhi",
  "latitude": 28.63,
  "longitude": 77.28,
  "jointExecutiveIds": [1002],
  "documents": [
    {
      "documentName": "Meeting Note",
      "fileName": "meeting-note.pdf",
      "fileSize": 12345
    }
  ],
  "followUps": [
    {
      "departmentId": 1,
      "followUpExecutiveId": 1002,
      "action": "Follow up for adoption decision",
      "followUpDate": "2026-09-15"
    }
  ],
  "sampling": {
    "executiveId": 1001,
    "shipmentModeId": 1,
    "items": [
      {
        "bookId": 1,
        "seriesId": 1,
        "requestedQty": 2,
        "samplingTypeId": 3,
        "sampleToContactId": 1,
        "sampleGiven": "TO_BE_DISPATCHED",
        "shipTo": "OFFICE_ADDRESS",
        "shippingAddress": "Demo Public School, Delhi"
      }
    ]
  }
}
```

If any child insert fails, the whole transaction rolls back.

---

# Original API reference -> V2 route mapping

The original API names are retained here only as a reference; the V2 uses cleaner REST-style routes and JSON arrays instead of XML strings.

| Original reference API                      | V2 equivalent                                             |
| ------------------------------------------- | --------------------------------------------------------- |
| Token function (user clarification)         | `POST /api/token`                                         |
| `Login`                                     | `POST /api/auth/login`                                    |
| `Logout`                                    | `POST /api/auth/logout`                                   |
| `forgotpassword`                            | `POST /api/auth/forgot-password`                          |
| `ChangePassword`                            | `POST /api/auth/change-password`                          |
| `getMenus`                                  | `GET /api/menus`                                          |
| `getsetupValues`                            | `GET /api/setup`                                          |
| `CheckincheckOut`                           | `POST /api/attendance/check-in`, `/check-out`             |
| `apiPlanList`                               | `GET /api/plans`                                          |
| `DSREntryApi`                               | `GET /api/visits/dsr-entry`                               |
| `apifollowupAction`                         | `GET /api/visits/follow-up-executives`                    |
| `ApiVisitEntry`                             | `POST /api/visits`                                        |
| `VisitDetails`                              | `GET /api/visits/details`                                 |
| `FetchTitles`                               | `GET /api/catalog/titles`                                 |
| `TitleNotInSeries`                          | `GET /api/catalog/titles/search`                          |
| `SeriesAndClassLevelList`                   | `GET /api/catalog/series-class-levels`                    |
| `SamplingDetails`                           | `GET /api/sampling/details`                               |
| `ShipmentMode`                              | `GET /api/catalog/shipment-modes`                         |
| `ShipTo`                                    | `GET /api/sampling/ship-to`                               |
| `ExecutiveLocationAPI`                      | `POST /api/attendance/locations`                          |
| `CustomerCreationAPI`                       | `POST /api/customers`, `PUT /api/customers/:id`           |
| `CustomerListAPI`                           | `GET /api/customers`                                      |
| `CustomerEntryMasterAPI`                    | `GET /api/customers/master-data`                          |
| `GeographyAPI`                              | `GET /api/geography`                                      |
| `BookSellerSearchAPI`                       | `GET /api/customers/book-sellers`                         |
| `ContactEntryorUpdateAPI`                   | `POST/PUT /api/contacts`                                  |
| `DeleteCustomerAPI`                         | `POST /api/customers/:id/delete-request`                  |
| `FetchCustomerDetails`                      | `GET /api/customers/:id`                                  |
| `FetchCustomerContactDetails`               | `GET /api/contacts/:id`                                   |
| `DeleteCustomerContactAPI`                  | `DELETE /api/contacts/:id`                                |
| `FetchCustomerContactList`                  | `GET /api/contacts/customer/:customerId`                  |
| `CityListForSearchCustomer`                 | `GET /api/customers/search-cities`                        |
| `SearchCustomerResult`                      | `GET /api/customers/search`                               |
| `CustomerSampling`                          | `POST /api/sampling/customer`                             |
| `selfstockSampling`                         | `POST /api/self-stock/requests`                           |
| `SelfStockRequestAPI`                       | `GET /api/self-stock/master-data`                         |
| `selfstockRequesttradeAPI`                  | `GET /api/self-stock/trade-addresses`                     |
| `CustomerSamplingApprovalList`              | `GET /api/sampling/approvals`                             |
| `CustomerSamplingApprovalDetails`           | `GET /api/sampling/requests/:id` + `/api/approvals/:id`   |
| `SubmitCustomerSamplingRequestApproval`     | `POST /api/approvals/:id/action`                          |
| `SubmitCustomerSamplingRequestBulkApproval` | `POST /api/approvals/bulk-action`                         |
| `SelfstockApprovalList`                     | `GET /api/self-stock/approvals`                           |
| `SelfStockSamplingApprovalDetails`          | `GET /api/self-stock/requests/:id` + `/api/approvals/:id` |
| `SubmitSelfStockSamplingApproval`           | `POST /api/approvals/:id/action`                          |
| `SubmitSelfStockSamplingBulkApproval`       | `POST /api/approvals/bulk-action`                         |

---

# Database grouping

```text
AUTH / ORGANIZATION
  api_clients
  api_tokens
  users
  refresh_tokens
  profiles
  executives
  departments
  product divisions / city / territory access

CONFIGURATION
  application_setup
  menus
  profile_menus

CUSTOMERS
  customers
  customer_school_details
  customer_contacts
  customer_categories
  customer_executives

FIELD WORK
  checkin_checkout
  executive_locations
  visit_plans
  backdate_requests
  visits
  visit_joint_executives
  visit_documents
  followups

CATALOG
  subjects
  class_levels
  series
  books
  shipment_modes
  sampling_types

SAMPLING
  sampling_budgets
  customer_sampling_requests
  customer_sampling_request_items

SELF STOCK
  self_stock_requests
  self_stock_request_items

APPROVALS
  approval_requests
  approval_history
  approval_item_history

OTHER
  notifications
  request_sequences
```

## Status separation

Sampling and Self Stock deliberately keep separate fields:

```text
request_status
approval_status
shipment_status
```

Final approval does not automatically mean the books have been shipped.

---

# Source-driven vs V2 implementation choices

Confirmed by the reference workflow:

- User and Executive are separate identifiers.
- Profile/hierarchy/access context matters.
- Check-In/Check-Out captures time + location.
- Visit can contain documents, follow-up, joint visit and sampling.
- Sampling uses books, quantities, sample recipient, shipping and budget information.
- Sampling and Self Stock use staged approval.
- Approval can reduce item quantity.
- Bulk approval/rejection exists.
- Request/approval/shipment status are distinct.

Implementation decisions made in this V2 because the source does not fully specify them:

- The shared API token endpoint/header implementation.
- Manager routing is calculated from `manager_executive_id` instead of trusting hierarchy strings sent by the frontend.
- The final approval level is the highest executive in the reporting chain rather than a fixed hard-coded level.
- `CS/MMYY/n` and `SS/MMYY/n` are generated with `request_sequences`.
- JSON arrays replace the original XML-in-JSON request fields.
- Customer/contact/backdate approvals use the same generic approval engine.

## September 2026 integration fixes

This package includes the fixes found while testing the Flutter app against backend:

- Customer Sampling now resolves `samplingTypeName` to `sampling_type_id` before SQL inserts and never sends JavaScript `undefined` values to mysql2.
- Sampling validates Customer, Contact, Shipment Mode and Sampling Type with readable 4xx errors instead of a generic SQL bind error.
- `POST /api/files/upload` now stores Visit PDF/JPG/JPEG/PNG documents (up to 10 MB) under `uploads/visit/` and returns the generated file name/URL.
- `/uploads/...` is served by Express for Visit Details document links.
- DSR Entry data now includes Academic Sessions, Sales Stages, Brands, Prospects, the `VisitBooksSampling`/`VisitEProducts` flags, and allowed visit date ranges.
- E-Product endpoints are included:
  - `GET /api/e-products/brands/:brandId/products`
  - `GET /api/e-products/:eProductId/details?academicSessionId=...&customerId=...`
- Visit Entry stores E-Product promotions and their classes.
- Visit Details returns the Customer even when that Customer has no previous Visit entry.
- The seeded menus now use the child-menu names already understood by the Flutter HomeScreen.

### If you already created your V2 database

Do **not** rerun `schema.sql` because it recreates the schema. Run only:

```text
database/patch_existing_database.sql
```

This patch realigns the demo menu rows and refreshes the two Visit feature flags. The Sampling/document/DSR fixes themselves are Node.js code changes and do not require dropping your database.

## V2.2 field-QA fixes

This build incorporates issues found during real-device Flutter testing:

- DSR Person Met accepts all non-deleted customer contacts; Flutter also performs a contact-list fallback.
- Catalog/title and sampling-title responses include `subject_id`, fixing Self Stock title selection.
- Sampling title responses include series/class/subject metadata.
- Customer class master exposes `class_num_id` so Nry/LKG/UKG and Class 1-12 map correctly.
- Customer details expose start/end business class numbers while storage continues to use `classes.id` foreign keys.
- Plan creation now derives `planType` from the request body correctly.
- No database schema migration is required when upgrading from the immediately previous V2 runtime-fixed database for these V2.2 changes.
