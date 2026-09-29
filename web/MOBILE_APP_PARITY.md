# DartCRM Web V3 — Flutter Function Parity

This build uses the latest `dart_crm_v4_admin_audit` Flutter project as the functional reference.

## School Visit / DSR

1. `School Visit - Search`
2. `School Visit - List`
3. Select a school -> `School Visit / DSR Entry`
4. Visit Date, Visit Purpose, Joint Visit, optional Person Met, Academic Session when E-Products are enabled
5. Sampling Done uses Title in Series / Title not in Series plus per-container Sampling Type, Sample To and Ship To
6. E-Products, Follow Up Action, document upload, Visit Feedback and browser geolocation
7. Submit to `/api/visits`

## Today / Tomorrow Plan

The React page has the same two tabs as Flutter and opens the selected customer detail before DSR Entry. The web client enriches plan cards from customer/geography data because the V4 `/plans` response is intentionally smaller than the historical API response.

## Customer Sampling

School, Trade and Library use the Flutter flow:

`Search -> Customer List -> Customer Detail -> Select Books -> Sampling Containers -> Shipment -> Submit`

The search screen uses Customer Name, Customer Code, contact/principal-teacher name and City. Every selected series is a separate sampling container; non-series books are separate containers. Each container supports Sampling Type, Sample Given, Sample To and Ship To. Shipment Mode, Shipping Instructions and Remarks are request-level values.

## Self-Stock

- Displays logged-in Executive Name.
- `Title in Series` and `Title not in Series` tabs.
- Quantity controls and Subject ID validation.
- Shipment Mode.
- Ship To: Residence Address, By Hand, Trade, Transport Office.
- Trade customer/address selector.
- Transport Official Address.
- Shipping Instructions and Remarks.
- Submit to the V4 Self-Stock approval workflow.

## Known backend-data differences

The React client does not fabricate data the V4 backend does not store. In particular, the current V4 schema has no school class-strength/enrollment-history table and no Past Adoption API. Those sections are identified in the UI instead of showing fake values.
