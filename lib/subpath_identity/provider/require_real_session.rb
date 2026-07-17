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
    # signed_in? would let that forged cookie reach them; gating on
    # rodauth.logged_in? doesn't, because forging that would require this
    # app's own SECRET_KEY_BASE, which no other app in the cluster has.
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
        redirect_to "/login" unless rodauth.logged_in?
      end
    end
  end
end
