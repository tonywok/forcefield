require 'forcefield/request'

module Forcefield
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      @request = Forcefield::Request.new(env)

      @request.with_valid_request do
        if client_verified?
          env["oauth_client"] = @client
          @app.call(env)
        else
          [401, {}, ["Unauthorized. You are part of the Rebel Alliance and a Trader!"]]
        end
      end
    end

    private

    def client_verified?
      @client = ImperialClient.find_by_consumer_key(@request.consumer_key)
      @request.verify_signature(@client)
    end

  end
end
