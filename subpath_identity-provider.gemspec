# frozen_string_literal: true

require_relative "lib/subpath_identity/provider/version"

Gem::Specification.new do |spec|
  spec.name = "subpath_identity-provider"
  spec.version = SubpathIdentity::Provider::VERSION
  spec.authors = ["Raghu Betina"]
  spec.email = ["raghu@firstdraft.com"]

  spec.summary = "Rodauth glue for the identity-owning app in a subpath_identity cluster."
  spec.description = "SCRIPT_NAME-aware redirects for Rodauth (mounted under a path prefix, neither " \
    "Rodauth nor Roda handles this on their own) and a before_action requiring a real Rodauth " \
    "session rather than the cross-app shared identity cookie, for the one app in a " \
    "subpath_identity cluster that owns accounts."
  spec.homepage = "https://github.com/raghubetina/subpath_identity-provider"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # >= 0.4: the documented login/signup hooks pass renew_lifetime: true
  # (added in core 0.4.0), and an identity owner must speak the same v3
  # wire format the 0.4 clients read.
  spec.add_dependency "subpath_identity", ">= 0.4", "< 1.0"
  spec.add_dependency "rodauth-rails", ">= 1.0"
  spec.add_dependency "activesupport", ">= 8.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
