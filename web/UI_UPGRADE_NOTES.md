# DartCRM Dashboard UI Upgrade Notes

## Scope

The uploaded DartCRM web frontend was redesigned to match the supplied dashboard reference while preserving the existing frontend-to-backend integration.

### Upgraded presentation

- Floating glassmorphism sidebar and top navigation
- Dark geometric/ambient dashboard background
- Red primary brand accent with cyan/green operational accents
- Glass cards, stat cards, tables, dialogs, form fields and workflow sections
- Dashboard-style login and reset-password screens
- Responsive sidebar and mobile layout
- Page-enter, hover, glow, pulse and button-sheen micro-animations
- Recharts styling adjusted to the new dark dashboard system
- Existing legacy screen surfaces normalized to the same visual language

## API safety

No API endpoint definitions or Axios behavior were changed.

The following integration files are intentionally preserved from the uploaded ZIP:

- `src/api/apiClient.js`
- `src/api/crmApi.js`
- `src/config/appConfig.js`
- `src/utils/storage.js`

This means the existing API token bootstrap, JWT login/refresh, routes, request payloads, query functions and mutations continue to use the same backend contract.

## Run

```bash
npm install
npm run dev
```

Use the same `.env` values/backend that you used with the original uploaded frontend.

## Reference Video Interaction Pack (2026-10-06)

The upgraded UI now also includes three reusable interaction patterns from the supplied reference videos:

1. **Desktop collapsible sidebar** — the glass sidebar collapses into an icon-only rail and expands back with a smooth width/content transition. The preference is persisted in localStorage. The existing mobile drawer behavior remains unchanged.
2. **Universal animated action buttons** — shared DartCRM `Button` controls now have a tactile click animation, animated fill/sweep, and an indeterminate progress treatment whenever their existing loading copy changes to text such as `Saving…`, `Submitting…`, `Signing in…`, `Uploading…`, etc. Existing API/loading state ownership remains in the feature pages.
3. **Animated document/file upload** — the Visit Documents panel now uses a drag/drop + browse UI with animated file cards, preview, Upload action, visual progress, success state and validation while continuing to call the original `fileApi.upload(file, "visit")` integration.

No API endpoint, request payload contract, token storage, route contract, or CRM API client implementation was changed for these UI additions.
