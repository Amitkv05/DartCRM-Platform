# Known limitations — V3 Flutter parity test build

1. The V4 backend does not currently store school class-wise enrollment/strength history, so the DSR School Enrollment panel cannot show the historical multi-year class-strength grid from the legacy CRM. The web client does not invent these numbers.
2. The V4 backend has no Past Adoption endpoint, so the DSR screen labels that function as unavailable rather than creating a fake API.
3. Customer Sampling contact-name search is supported by checking customer contacts after the main customer filters. This can make a broad contact-only search slower than name/code/city search because Backend V4 does not expose a dedicated contact-name customer-search filter.
4. For Self-Stock Residence Address, Backend V4 does not expose a logged-in executive residential-address API. The test build therefore lets the executive enter the residence shipping address manually. Trade addresses are loaded from the real V4 API.
5. Browser geolocation behavior is controlled by browser/OS permissions; unlike Flutter, a web page cannot directly switch device Location Services on.
