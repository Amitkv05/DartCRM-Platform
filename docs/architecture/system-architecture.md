# DartCRM System Architecture

## High-Level Architecture

```mermaid
flowchart LR
    subgraph Clients
      WEB[React Web Application]
      MOBILE[Flutter Mobile Application]
    end

    WEB -->|HTTPS / REST / JSON| API
    MOBILE -->|HTTPS / REST / JSON| API

    subgraph Backend
      API[Node.js + Express API]
      AUTH[Authentication / Authorization]
      BUSINESS[CRM Business Logic]
      AUDIT[Audit / Request History]
      FILES[File Handling]
    end

    API --> AUTH
    API --> BUSINESS
    API --> AUDIT
    API --> FILES
    BUSINESS --> DB[(MySQL)]
    AUTH --> DB
    AUDIT --> DB
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant C as Web / Mobile Client
    participant A as API
    participant D as MySQL

    C->>A: Login credentials
    A->>D: Validate user and permissions
    D-->>A: User / role data
    A-->>C: Access token + session response
    C->>A: Authenticated API request
    A->>A: Validate token and authorization
    A->>D: Read / write CRM data
    D-->>A: Result
    A-->>C: JSON response
```

## Shared Backend Model

The React web application and Flutter mobile application are separate clients of the same backend. Core business rules should remain server-side so that behavior stays consistent across both clients.

```text
React Web -----------\
                      >---- Node.js / Express ---- MySQL
Flutter Mobile ------/
```

## Main Domains

The platform currently covers CRM domains such as customers, contacts, visits, attendance, sampling, self-stock, approvals, notifications, administration and audit/request history.

## Production Notes

- Use HTTPS for production API traffic.
- Keep database credentials, JWT secrets and service credentials server-side.
- Restrict production CORS origins.
- Protect private uploaded files with authentication/authorization where appropriate.
- Use sanitized demo data in public portfolio environments.
- Do not commit signing keys, `.env` files or production database exports.
