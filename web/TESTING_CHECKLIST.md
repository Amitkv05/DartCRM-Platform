# DartCRM Web V3 — Field Workflow Test Checklist

## 1. Login / token
- Start Backend V4.
- Start React.
- First request should generate `/api/token` automatically.
- Login should attach `x-api-token`; protected APIs should additionally attach the Bearer JWT.

## 2. School Visit / DSR
- Open Visit Entry menu. It must open School Visit - Search, not a generic DSR form.
- Search by school name/code/country/state/district/city.
- Result list should show customer name/code/address/city/state.
- Click row -> DSR detail.
- Check Executive Name, date, purpose, optional Person Met, Joint Visit.
- Test browser location denied and allowed.
- Test Sampling Done with Title in Series and Title not in Series.
- Test multiple series: each container should have its own Sample To / Ship To.
- Test E-Product, Follow Up, document upload, feedback, submit.

## 3. Today / Tomorrow Plan
- Open Today's Plan.
- Switch/open Tomorrow's Plan.
- Check customer card fields and purpose.
- Click plan -> Plan Details.
- Click DSR Entry -> selected customer DSR screen.

## 4. School / Trade / Library Sampling
For every customer type:
- Search by customer name/code/contact/city.
- Open customer from list.
- Select a Title in Series.
- Select a Title not in Series.
- Change quantities.
- Set Sampling Type, Sample Given, Sample To, Ship To per container.
- Select Shipment Mode.
- Enter Shipping Instructions / Remarks.
- Submit and verify request appears in My Request History.

## 5. Self-Stock
- Executive Name must be the logged-in executive.
- Test both title tabs.
- Verify selected books contain valid Subject ID.
- Test Residence Address.
- Test By Hand.
- Test Trade and verify selected trade address.
- Test Transport Office address.
- Submit and verify request history.

## Bug report
Send: screen, login/profile, clicks, expected result, actual result, Network request/response, console error, and screenshot.
