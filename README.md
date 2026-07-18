# SubpathIdentity::Provider

Rodauth glue for the one app that owns identity in a [`subpath_identity`](https://github.com/raghubetina/subpath_identity) cluster — a set of independently deployed Rails apps living under one domain by path (`mydomain.com/`, `mydomain.com/app1`), where only one app runs Rodauth and every other app is a relying party (see [`subpath_identity-client`](https://github.com/raghubetina/subpath_identity-client)).

This gem is small on purpose. Most of what an identity-owning app needs is just Rodauth configuration specific to that app's own account schema and feature set — there isn't much to abstract. What's here are the two things that are genuinely the same across any app in this position, plus documented patterns (not code, since they depend on your own `Account` model and feature list) for the rest.

## Installation

```bash
bundle add subpath_identity-provider
```

## What's in the gem

**SCRIPT_NAME-aware redirects.** If this app is mounted under a path prefix behind the same router as its relying parties (`config.ru`'s `map(ENV["RAILS_RELATIVE_URL_ROOT"])`, or however your router sets `SCRIPT_NAME`), Rodauth's own redirects don't know about it — confirmed by reading both Rodauth's and Roda's source, neither references `SCRIPT_NAME` anywhere. Rails' own `redirect_to` handles this automatically; Rodauth's don't.

```ruby
# app/misc/rodauth_main.rb
configure do
  home = SubpathIdentity::Provider::RodauthRedirects.home
  default_redirect(&home)
  login_redirect(&home)
  logout_redirect(&home) # doesn't fall through to default_redirect — needs its own override
end
```

**Requiring a real session, not the shared cookie.** `subpath_identity`'s shared identity cookie proves who to display, not who's allowed to write — every app in the cluster holding `SHARED_SESSION_SECRET` can mint one (that's how a relying party writes a shared preference, like a dark-mode toggle). Gate this app's own mutations — anything that changes an account — behind the real Rodauth session instead:

```ruby
class ProfilesController < ApplicationController
  include SubpathIdentity::Provider::RequireRealSession
end
```

This calls `rodauth.require_account`, not `rodauth.logged_in?` — `logged_in?` only checks that the session carries an account id, with no account lookup at all, so a closed or deleted account would keep a previously issued session usable indefinitely. `require_account` re-fetches the account filtered by status and clears the session before redirecting if that lookup comes back empty.

### `require_account` alone does nothing until status checks are on

That status filter only actually excludes anything once your app's own `skip_status_checks?` is `false`. Rodauth defaults it to `true` unless you enable the `:close_account` or `:verify_account` feature (either flips it), or set it explicitly:

```ruby
configure do
  skip_status_checks? false
end
```

Until you do one of those, `require_account` behaves exactly like `logged_in?` — a closed account keeps working. If your app has never enabled status checks, turning them on for the first time needs a data migration *before* the config change ships, not after:

Rodauth's own signup path (`_new_account`) only assigns an explicit initial status when `skip_status_checks?` is already `false`. Every account created while it was `true` never had a status explicitly set by Rodauth at all — it's sitting on whatever your database column's plain default is. If that default isn't the same value as `account_open_status_value` (2, unless you've changed it), flipping `skip_status_checks?` to `false` will lock out every existing account that was ever created, not just closed ones — this is a "log every single user out" bug, not a narrow fix.

Before enabling status checks on an app with existing accounts, back-fill *only* the rows sitting on your column's raw, never-explicitly-set default — not a blanket `WHERE status != 2`, which would just as happily re-open any account you'd already closed some other way (a manual console edit, your own ad-hoc admin action) before this migration ever ran:

```ruby
class BackfillAccountStatusAndFixDefault < ActiveRecord::Migration[8.1]
  def up
    # Adjust the table/column name and status values to your own schema.
    # `1` here is whatever your status column's database default has
    # been all along (check it — Rodauth never set it explicitly while
    # skip_status_checks? was true, so every existing row is sitting on
    # that raw default, not on account_open_status_value). `2` is
    # account_open_status_value's own default; check yours if you've
    # changed it. Target only rows still on the untouched default —
    # never touch rows already at some other status on purpose.
    execute "UPDATE accounts SET status = 2 WHERE status = 1"
    change_column_default :accounts, :status, from: 1, to: 2
  end

  def down
    change_column_default :accounts, :status, from: 2, to: 1
    # Deliberately not reverting status back to 1: there's no way to
    # tell which rows were on-the-default vs. genuinely reached status
    # 2 some other way.
  end
end
```

Run this, confirm existing accounts still log in, *then* set `skip_status_checks? false`. Skipping the migration and finding out from your users is the alternative.

## Patterns this gem doesn't abstract

**Writing the shared cookie on login and signup.** Wire both hooks, not just one — Rodauth's `create_account` autologin path (`autologin_session`, on by default via `create_account_autologin?`) sets the session directly and never calls `after_login`, so a signup without a following login step would leave the cookie unset with only one hook wired:

```ruby
configure do
  after_create_account { write_shared_identity_cookie }
  after_login { write_shared_identity_cookie }
end

private

# `account` inside a Rodauth hook is Rodauth's own Sequel-backed Hash,
# not an ActiveRecord instance — re-fetch the real record first.
def write_shared_identity_cookie
  record = Account.find(account_id)
  rails_controller_eval { write_shared_identity(user_id: record.id, cache_key: record.cache_key_with_version) }
end
```

**An internal profile API for relying parties to call.** `subpath_identity-client`'s `RootProfileClient` expects a JSON endpoint authenticated by the caller forwarding the same shared identity cookie it already has:

```ruby
class InternalController < ApplicationController
  def me
    return head(:unauthorized) unless signed_in?

    account = Account.find_by(id: current_shared_identity[:user_id])
    # verified?, not just present — this endpoint is the profile
    # relying parties cache locally (see subpath_identity-client's
    # SyncLocalProfile), and a closed account should look like no
    # account at all here too, not just on this app's own mutations,
    # or a relying party keeps showing and caching a closed account's
    # data forever.
    return head(:not_found) unless account&.verified?

    render json: {user_id: account.id, email: account.email, cache_key: account.cache_key_with_version}
  end
end
```

Remember to add this path to `worker_origin_exempt_paths` in your `subpath_identity` configuration — it's called server-to-server and never goes through the router. And remember this only actually excludes a closed account once `skip_status_checks?` is `false` (see above) — `verified?` just reads the AR enum directly, so it's correct as soon as your accounts' status values actually mean something, independent of Rodauth's own session-side check.

Both of these stay as documentation rather than gem code because they're inherently tied to your own `Account` model and whatever fields you want to expose — an abstraction here would add indirection without removing real duplication.

## Development

`bin/setup`, then `bundle exec rake test`. `bundle exec standardrb` for style.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/raghubetina/subpath_identity-provider.

## License

MIT.
