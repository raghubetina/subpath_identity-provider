# frozen_string_literal: true

require "active_support/concern"

module SubpathIdentity
  module Provider
    # Include in any controller whose actions should require this app's
    # real Rodauth session (backed by its own session cookie and
    # SECRET_KEY_BASE) rather than the cross-app shared identity cookie
    # (subpath_identity's SharedIdentity, exposed via signed_in?).
    #
    # The shared cookie proves who to display; it does not prove who's
    # allowed to write. Every app in the cluster holding
    # SHARED_SESSION_SECRET can mint one — that's necessary for something
    # as simple as a shared dark-mode toggle written from a relying-party
    # app, but it means a compromised relying party could forge a shared
    # identity for any user_id. Gating this app's own mutations on
    # signed_in? would let that forged cookie reach them; gating on a
    # real Rodauth session doesn't, because forging that would require
    # this app's own SECRET_KEY_BASE, which no other app in the cluster
    # has.
    #
    # rodauth.require_account, not rodauth.logged_in? — logged_in? is
    # only "does the session have an account_id in it," with no account
    # lookup at all, so a closed or deleted account keeps a previously
    # issued session usable forever. require_account (rodauth-rails'
    # own documented pattern for protecting a plain Rails controller —
    # see its README, "You can also require authentication at the
    # controller layer") re-fetches the account filtered by status
    # (open/unverified, controlled by skip_status_checks?) and clears
    # the session before redirecting if that lookup comes back empty.
    #
    # Requires rodauth-rails, which wires the `rodauth` helper into every
    # controller automatically.
    module RequireRealSession
      extend ActiveSupport::Concern

      included do
        before_action :require_rodauth_session!
      end

      private

      def require_rodauth_session!
        rodauth.require_account
      end
    end
  end
end
