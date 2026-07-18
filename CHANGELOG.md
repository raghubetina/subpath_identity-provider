## [Unreleased]

- `RequireRealSession` now calls `rodauth.require_account` instead of `rodauth.logged_in?`, so a closed or deleted account no longer keeps a previously issued session usable. This only takes effect once your app's own `skip_status_checks?` is `false` — see the README section "`require_account` alone does nothing until status checks are on" before enabling it on an app with existing accounts; it needs a data migration first, or you'll lock out every existing account, not just closed ones.

## [0.1.0] - 2026-07-16

- Initial release
