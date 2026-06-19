# Security Policy

## Supported Versions

This repository is maintained from the `main` branch. Security fixes are applied to the latest version of the workflow and Docker configuration in this repository.

## Reporting a Vulnerability

Do not open a public issue for secrets, credential leaks, or exploitable vulnerabilities.

Report security issues privately through GitHub Security Advisories when available, or contact the repository owner directly. Include:

- A clear description of the issue.
- Steps to reproduce the issue.
- Affected files, workflow nodes, or configuration values.
- Any known impact or workaround.

## Secret Handling

Never commit `.env`, n8n credential exports, PM source archives, generated client reports, Cloudflare tokens, Telegram tokens, Google OAuth credentials, or MariaDB credentials.
