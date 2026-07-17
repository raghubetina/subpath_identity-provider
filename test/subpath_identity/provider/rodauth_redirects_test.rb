# frozen_string_literal: true

require "test_helper"

class RodauthRedirectsTest < Minitest::Test
  def test_home_returns_a_callable_that_reads_script_name_from_the_request_env
    home = SubpathIdentity::Provider::RodauthRedirects.home

    fake_rodauth_context = Object.new
    fake_request = Struct.new(:env).new({"SCRIPT_NAME" => "/blog"})
    fake_rodauth_context.define_singleton_method(:request) { fake_request }

    assert_equal "/blog/", fake_rodauth_context.instance_exec(&home)
  end

  def test_home_resolves_to_bare_slash_when_script_name_is_empty
    home = SubpathIdentity::Provider::RodauthRedirects.home

    fake_rodauth_context = Object.new
    fake_request = Struct.new(:env).new({"SCRIPT_NAME" => ""})
    fake_rodauth_context.define_singleton_method(:request) { fake_request }

    assert_equal "/", fake_rodauth_context.instance_exec(&home)
  end
end
