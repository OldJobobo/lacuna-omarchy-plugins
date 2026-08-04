# Support and bug reports

Status: user support guide for the latest beta

Use the project issue tracker for reproducible defects and feature requests:

- [Open a bug report](https://github.com/OldJobobo/lacuna-shell/issues/new?template=bug_report.md)
- [Request a feature](https://github.com/OldJobobo/lacuna-shell/issues/new?template=feature_request.md)
- [Browse existing issues](https://github.com/OldJobobo/lacuna-shell/issues)

## Before opening a bug

1. Read [Troubleshooting](troubleshooting.md).
2. Check [Known limitations](known-limitations.md).
3. Update to the latest appropriate package/source revision.
4. Reproduce once after `omarchy restart shell`.
5. Confirm whether `omarchy bar reset` changes the problem.

## Include

- Lacuna version (`VERSION` or About)
- Exact Omarchy and Quickshell versions
- Redacted `lacuna-shell status` output
- The command or UI action that triggered the problem
- Expected and actual behavior
- Minimal reproduction steps
- Relevant monitor names, resolution, scale, and bar edge
- A screenshot or short capture for visible issues
- Shell/QML errors around the failure, if available

## Remove before sharing

- API keys and access tokens
- Cookies and cookie-file contents
- Jellyfin user IDs or private server URLs
- Authenticated media URLs
- Private file paths when they reveal personal information
- Unrelated window titles, notifications, and usernames

Do not upload the whole Lacuna state directory. Share the smallest redacted
excerpt that demonstrates the issue.

## Feature requests

Describe the user problem before proposing a plugin or implementation. Lacuna
prefers Omarchy-native services for rich system behavior and owns the
presentation only where a distinct Lacuna workflow or form is useful.

## Security-sensitive reports

Do not publish credentials or an exploit containing private data in a public
issue. If a private security-reporting channel is not available on the
repository, open a minimal issue that asks the maintainer for a private contact
without disclosing the sensitive details.
