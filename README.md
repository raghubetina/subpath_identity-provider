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
    return head(:not_found) unless account

    render json: {user_id: account.id, email: account.email, cache_key: account.cache_key_with_version}
  end
end
```

Remember to add this path to `worker_origin_exempt_paths` in your `subpath_identity` configuration — it's called server-to-server and never goes through the router.

Both of these stay as documentation rather than gem code because they're inherently tied to your own `Account` model and whatever fields you want to expose — an abstraction here would add indirection without removing real duplication.

## Development

`bin/setup`, then `bundle exec rake test`. `bundle exec standardrb` for style.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/raghubetina/subpath_identity-provider.

## License

MIT.
