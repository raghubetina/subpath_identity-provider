# frozen_string_literal: true

require "test_helper"

class RequireRealSessionTest < Minitest::Test
  # Rodauth's own require_account is what actually decides redirect vs.
  # pass-through — it re-fetches the account filtered by status, so
  # "not logged in" and "logged in but the account is closed/deleted"
  # both fail it the same way. That's Rodauth's own behavior to prove,
  # not this gem's; this fake just stands in for whichever of those
  # require_account itself would reject.
  class FakeController < ActionController::Base
    include SubpathIdentity::Provider::RequireRealSession

    attr_accessor :fake_valid_account_session

    def rodauth
      controller = self
      valid = fake_valid_account_session
      Object.new.tap do |fake|
        fake.define_singleton_method(:require_account) do
          controller.send(:redirect_to, "/login") unless valid
        end
      end
    end

    def index
      head :ok
    end
  end

  def test_redirects_to_login_when_rodauth_has_no_valid_account_session
    controller = FakeController.new
    controller.fake_valid_account_session = false
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new

    controller.process(:index)

    assert_equal 302, controller.response.status
    assert_equal "http://test.host/login", controller.response.location
  end

  def test_allows_the_request_through_when_rodauth_has_a_valid_account_session
    controller = FakeController.new
    controller.fake_valid_account_session = true
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new

    controller.process(:index)

    assert_equal 200, controller.response.status
  end
end
