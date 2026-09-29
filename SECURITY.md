# Security Policy

## Supported Version

This repository is maintained as a portfolio and engineering showcase. Security fixes are applied to the current `main` branch.

## Reporting a Security Issue

Do not publish credentials, tokens or vulnerability details in a public GitHub issue.

If GitHub Private Vulnerability Reporting is enabled for this repository, use it to report security issues privately. Otherwise, contact the repository owner through a private channel before sharing technical details.

## Repository Security Rules

Never commit any of the following:

- `.env` files containing real values
- Database passwords or connection credentials
- JWT/access/refresh secrets
- Production API keys or service secrets
- Android/iOS signing keys, keystores or key passwords
- Real customer or employee documents
- Production database dumps
- Access tokens or refresh tokens

Only sanitized `.env.example` templates should be committed.

## If a Secret Is Accidentally Committed

1. Rotate or revoke the exposed secret immediately.
2. Remove the secret from the current repository state.
3. Rewrite Git history if the repository was shared publicly and the secret must be removed from previous commits.
4. Verify that the old credential no longer works.
5. Review logs and account activity where appropriate.

Removing a secret from the latest commit does not make an exposed credential safe; rotation is still required.

## Production Recommendations

- Use HTTPS for web and mobile API traffic.
- Restrict CORS to approved frontend origins.
- Keep privileged service credentials on the backend rather than embedding them in browser or mobile clients.
- Apply authentication and authorization to private file access.
- Validate and sanitize API input.
- Keep dependencies updated and review CI failures before deployment.
