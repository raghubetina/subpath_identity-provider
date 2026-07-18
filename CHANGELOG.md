## [Unreleased]

## [0.2.1] - 2026-07-18

- Install docs now use a GitHub source (the gems aren't on RubyGems yet, so `bundle add` can't resolve them). No code change.

## [0.2.0] - 2026-07-18

- `RequireRealSession` now calls `rodauth.require_account` instead of `rodauth.logged_in?`, so a closed or deleted account no longer keeps a previously issued session usable. This only takes effect once your app's own `skip_status_checks?` is `false` — see the README section "`require_account` alone does nothing until status checks are on" before enabling it on an app with existing accounts; it needs a data migration first, or you'll lock out every existing account, not just closed ones.
- Requires `subpath_identity >= 0.2` — an identity owner writes the shared cookie through core's `ControllerHelpers`, so it must speak the same v2 wire format the 0.2 clients read.

## [0.1.0] - 2026-07-16

- Initial release
