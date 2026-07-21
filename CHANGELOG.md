## [Unreleased]

## [0.2.4] - 2026-07-21

- Core dependency floor raised to `>= 0.5` (its `write_shared_identity` now composes multiple writes in one request, which the client relies on). No code change in this gem.

## [0.2.3] - 2026-07-21

- The documented login/signup hook pattern now passes `renew_lifetime: true` to `write_shared_identity` — real authentication is what earns a fresh absolute cookie lifetime (core 0.4.0's v3 wire format makes the deadline absolute; ordinary writes carry it forward unchanged). Core floor rises to `>= 0.4` accordingly.
- `required_ruby_version` raised to `>= 3.3` and CI runs the declared floor against the committed lockfile (the lock pins `parallel 2.1.0`, whose own floor is Ruby 3.3).

## [0.2.2] - 2026-07-18

- The documented internal profile endpoint now returns a typed `410 {"error": "account_gone"}` for a closed/unknown account instead of a bare 404, matching `subpath_identity-client` 0.3.0's revocation protocol (an untyped 404 no longer revokes — deploy-skew safety). Docs only; safe to upgrade in either order.
- Declared Rails floor raised to `>= 8.1` — the toolchain CI actually tests. Rails 7 was never deliberately supported, only inherited from scaffolding defaults.

## [0.2.1] - 2026-07-18

- Install docs now use a GitHub source (the gems aren't on RubyGems yet, so `bundle add` can't resolve them). No code change.

## [0.2.0] - 2026-07-18

- `RequireRealSession` now calls `rodauth.require_account` instead of `rodauth.logged_in?`, so a closed or deleted account no longer keeps a previously issued session usable. This only takes effect once your app's own `skip_status_checks?` is `false` — see the README section "`require_account` alone does nothing until status checks are on" before enabling it on an app with existing accounts; it needs a data migration first, or you'll lock out every existing account, not just closed ones.
- Requires `subpath_identity >= 0.2` — an identity owner writes the shared cookie through core's `ControllerHelpers`, so it must speak the same v2 wire format the 0.2 clients read.

## [0.1.0] - 2026-07-16

- Initial release
