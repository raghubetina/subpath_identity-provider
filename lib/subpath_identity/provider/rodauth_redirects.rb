# frozen_string_literal: true

module SubpathIdentity
  module Provider
    module RodauthRedirects
      class << self
        # Neither Rodauth nor Roda (the framework it's built on) is aware
        # of SCRIPT_NAME anywhere in their redirect handling — confirmed
        # by reading both gems' source. Rails' own redirect_to does this
        # automatically, since it reads SCRIPT_NAME as part of building
        # any relative URL; Rodauth's redirects default to a literal path
        # and don't.
        #
        # Wire this into every redirect Rodauth has, not just
        # default_redirect — logout_redirect specifically doesn't fall
        # through to default_redirect, so it needs its own override or a
        # post-logout redirect lands on whatever app happens to own "/",
        # not the app the visitor was actually using:
        #
        #   home = SubpathIdentity::Provider::RodauthRedirects.home
        #   default_redirect(&home)
        #   login_redirect(&home)
        #   logout_redirect(&home)
        def home
          -> { "#{request.env["SCRIPT_NAME"]}/" }
        end
      end
    end
  end
end
