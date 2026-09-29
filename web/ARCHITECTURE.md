# DartCRM Web V2 Architecture

## Core data flow

`Page / Feature -> TanStack Query/Mutation -> crmApi -> Axios -> CRM Backend V4 -> MySQL`

Redux is limited to browser/global client state: current executive, JWT session context, backend-generated menus, hierarchy/setup cache and UI state. TanStack Query owns API/server data.

## Authentication flow (same contract as Flutter)

```text
Browser starts
   |
   +-> AuthBootstrap
         |
         +-> ensureApiToken()
               |
               +-> valid saved x-api-token -> reuse
               |
               +-> no/expired token -> POST /api/token

Executive Login
   |
   +-> ensureApiToken()
   +-> POST /api/auth/login
   +-> save accessToken + refreshToken + user/context
   +-> GET /api/menus
   +-> GET /api/setup
   +-> GET /api/executives/me/hierarchy

Every protected API
   |
   +-> x-api-token: <shared application token>
   +-> Authorization: Bearer <executive JWT>

401 from expired API token -> regenerate API token -> retry once
401 from expired JWT       -> refresh access token -> retry once
invalid refresh token      -> clear executive session -> Login
```

## Source layout

- `src/api` - Axios client, token/JWT retry logic and CRM endpoint services
- `src/app` - Redux and TanStack Query clients
- `src/components/auth` - startup/session bootstrap
- `src/components/common` - reusable error/loading/table/form components
- `src/components/layout` - sidebar/topbar/app shell
- `src/config` - browser-safe app configuration defaults
- `src/features` - CRM modules by business feature
- `src/routes` - public/protected/Admin routing
- `src/schemas` - Zod validation
- `src/utils` - local storage, formatting and API error helpers

## Authorization

The backend is the security boundary. `/api/menus` decides what the logged-in executive should see. React route guards improve UX, while CRM Backend V4 independently validates API token, JWT, Admin role, approval assignment and hierarchy permissions.

## Production browser security

The current local test design intentionally mirrors the Flutter demo service-client bootstrap. Browser JavaScript cannot keep a compiled service secret private. Before public deployment, replace browser-side service-client bootstrap with a BFF/server exchange or revise the backend token model.
