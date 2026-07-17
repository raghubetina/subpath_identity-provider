# frozen_string_literal: true

require "test_helper"

class RequireRealSessionTest < Minitest::Test
  class FakeController < ActionController::Base
    include SubpathIdentity::Provider::RequireRealSession

    attr_accessor :fake_rodauth_logged_in

    def rodauth
      Struct.new(:logged_in?).new(fake_rodauth_logged_in)
    end

    def index
      head :ok
    end
  end

  def test_redirects_to_login_when_rodauth_session_is_not_logged_in
    controller = FakeController.new
    controller.fake_rodauth_logged_in = false
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new

    controller.process(:index)

    assert_equal 302, controller.response.status
    assert_equal "http://test.host/login", controller.response.location
  end

  def test_allows_the_request_through_when_rodauth_session_is_logged_in
    controller = FakeController.new
    controller.fake_rodauth_logged_in = true
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new

    controller.process(:index)

    assert_equal 200, controller.response.status
  end
end
