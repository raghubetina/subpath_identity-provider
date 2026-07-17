# frozen_string_literal: true

require "subpath_identity"
require_relative "provider/version"
require_relative "provider/rodauth_redirects"
require_relative "provider/require_real_session"

# For the one app in a subpath_identity cluster that owns identity —
# runs Rodauth, has the only password/passkey/OAuth to check, and is the
# only app that ever mints a user_id. See subpath_identity-client for the
# apps that read from it instead.
module SubpathIdentity
  module Provider
    class Error < StandardError; end
  end
end
