require 'rack/auth/abstract/request'

module Forcefield
  class Request < Rack::Auth::AbstractRequest

    def with_valid_request
      if provided?
        if !oauth?
          [401, {}, ["Unauthorized. Pst! You forgot to include the Auth scheme"]]
        elsif params[:consumer_key].nil?
          [401, {}, ["Unauthorized. Pst! You forgot the consumer key"]]
        elsif params[:signature].nil?
          [401, {}, ["Unauthorized. Pst! You forgot to sign the request."]]
        elsif params[:signature_method].nil?
          [401, {}, ["Unauthorized. Pst! You forgot to include the OAuth signature method."]]
        else
          yield(request.env)
        end
      else
        [401, {}, ["Unauthorized. You are part of the Rebel Alliance and a Trader!"]]
      end
    end

    def verify_signature(client)
      return false unless client

      header = SimpleOAuth::Header.new(request.request_method, request.url, included_request_params, auth_header)
      header.valid?(:consumer_secret => client.consumer_secret)
    end

    def consumer_key
      params[:consumer_key]
    end

    private

    def params
      @params ||= SimpleOAuth::Header.parse(auth_header)
    end

    def oauth?
      scheme == :oauth
    end

    def auth_header # :nodoc:
      @env[authorization_key]
    end

    def included_request_params # :nodoc:
      request.content_type == "application/x-www-form-urlencoded" ? request.params : nil
    end
  end
end
