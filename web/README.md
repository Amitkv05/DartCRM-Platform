# DartCRM Web V3 - Mobile Parity Test Build

React + Vite web client for CRM Backend V4 (`4.0-admin-audit`). It uses the same backend, shared application-token flow, executive login/JWT flow, hierarchy, menus, approvals and business APIs as the Flutter CRM app.

## Stack

- React + Vite + JavaScript
- React Router
- Redux Toolkit
- TanStack Query
- Axios
- React Hook Form + Zod
- Tailwind CSS + Radix/shadcn-style primitives
- TanStack Table
- Recharts
- Lucide React
- Sonner

## Important: automatic API token generation

For LOCAL testing you no longer need to paste an API token into the React `.env`.

Create `.env` beside `package.json`:

```env
VITE_API_BASE_URL=http://localhost:5000/api
```

That is enough for the current test backend. The website mirrors the Flutter test app and uses the demo service client to call:

```text
POST /api/token
    -> saves shared x-api-token
    -> every API automatically receives x-api-token
    -> login creates JWT
    -> protected APIs also receive Authorization: Bearer <JWT>
```

The API token is reused until it expires/revokes. Axios automatically regenerates it and retries once. Expired JWT access tokens are refreshed with the stored refresh token and the original request is retried.

You can optionally override the local test service client via the `VITE_CRM_SERVICE_EMAIL` and `VITE_CRM_SERVICE_SECRET` variables in `.env.example`.

> Browser security: Vite variables and any browser-side service credential are visible in the built JavaScript. This matches the current local Flutter/test workflow only. Before a public production deployment, move application-token bootstrap behind a server/BFF or change the backend contract.

## Run

```bash
npm install
npm run dev
```

Open `http://localhost:5173`.

Backend should be running on port 5000 and `/health` should report V4.

## Authentication parity with Flutter

- automatic application API-token creation
- API-token storage + expiry reuse
- automatic API-token regeneration
- executive email/password login
- JWT access + refresh token storage
- automatic access-token refresh
- browser refresh/session restoration
- backend menu reload
- application setup reload
- hierarchy reload
- forgot-password request
- reset-password screen
- change password
- logout while keeping reusable application API token

## CRM modules

- Role-aware Dashboard and menus
- School / Trade / Library / Institute customer lists
- Customer create/update/delete approval lifecycle
- Customer contacts
- Today / Tomorrow plans and plan creation
- Visit / DSR entry
- optional Person Met
- joint visit executives
- browser GPS capture
- visit document upload
- E-Product promotion
- Visit Backdate Request
- Customer Sampling
- Self-Stock
- shared catalogue/title APIs
- Customer/Self-Stock approval with editable quantities
- Approve & Forward / Final Approve
- Customer Create/Update/Delete approval
- Contact approval
- Visit Backdate approval
- My Request History
- Notifications -> approval detail
- Attendance check-in/out
- E-Product catalogue
- Admin User & Role Management
- Admin Request & Approval History
- Individual/bulk completed-history removal
- global UI error boundary + API request IDs in errors

## Mobile parity rule

The web client exposes the functions backed by the current V4 API. Old Flutter screens that have no V4 backend contract are not given fake browser behavior. See `MOBILE_APP_PARITY.md`.


## Flutter workflow parity update

V3 rebuilds the field workflows around the current `dart_crm` mobile application rather than using generic web forms.

- School Visit: Search -> customer list -> DSR Entry detail.
- View Today's Plan / View Tomorrow's Plan: same tab/list/detail flow.
- School / Trade / Library Sampling: Search -> result list -> customer sampling detail -> multi-container title/delivery configuration.
- Self-Stock: executive detail -> Title in Series / Title not in Series -> shipment/Ship To -> request submission.
- DSR Sampling Done uses the same per-series/title Sample To / Ship To container logic as standalone Customer Sampling.

The V4 backend remains the system of record; the React client does not invent unsupported data.
