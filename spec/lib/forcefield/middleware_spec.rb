require 'spec_helper'

describe Forcefield::Middleware do

  let(:death_star) { lambda { |env| [200, {}, []] } }
  let(:middleware) { Forcefield::Middleware.new(death_star) }
  let(:mock_request) { Rack::MockRequest.new(middleware) }

  context "incoming request has no Authorization header" do

    let(:resp) { mock_request.get("/") }

    it("returns a 401") { resp.status.should == 401 }

    it "notifies the client they are Unauthorized" do
      resp.body.should == "Unauthorized. You are part of the Rebel Alliance and a Trader!"
    end

  end

  context "incoming request has a Authorization header" do
    context "when incoming request has a Authorization header" do
      context "but is missing an OAuth Authorization scheme" do

        let(:header_with_bad_scheme) {{ "HTTP_AUTHORIZATION" => "Force" }}
        let(:resp) { mock_request.get("/", header_with_bad_scheme) }

        it("returns a 401") { resp.status.should == 401 }

        it "notifies client that they sent the wrong Authorization scheme" do
          resp.body.should == "Unauthorized. Pst! You forgot to include the Auth scheme"
        end
      end

      context "but is missing an oauth_consumer_key" do

        let(:header_with_no_key) {{ "HTTP_AUTHORIZATION" => "OAuth realm=\"Endor\"" }}
        let(:resp) { mock_request.get("/", header_with_no_key) }

        it("returns a 401") { resp.status.should == 401 }

        it "notifies the client that they have not included a consumer key" do
          resp.body.should == "Unauthorized. Pst! You forgot the consumer key"
        end
      end

      context "but is missing an oauth_signature" do

        let(:header_without_sig) {{ "HTTP_AUTHORIZATION" => "OAuth realm=\"foo\", oauth_consumer_key=\"123\"" }}
        let(:resp) { mock_request.get("/", header_without_sig) }

        it("returns a 401") { resp.status.should == 401 }

        it "notifies the client that they have not signed the request" do
          resp.body.should == "Unauthorized. Pst! You forgot to sign the request."
        end
      end

      context "but is missing an oauth_signature_method" do

        let(:header_without_sig_method) do
          { "HTTP_AUTHORIZATION" => "OAuth realm=\"foo\", oauth_consumer_key=\"123\", oauth_signature=\"SIGNATURE\"" }
        end
        let(:resp) { mock_request.get("/", header_without_sig_method) }

        it("returns a 401") { resp.status.should == 401 }

        it "notifies the client that they haven't specified how they signed the request" do
          resp.body.should == "Unauthorized. Pst! You forgot to include the OAuth signature method."
        end

      end
    end

    context 'client makes request with sufficient, but incorrect OAuth header' do

      let(:test_uri) { "http://api.deathstar.com" }
      let(:incorrect_secret) { "!!#{ImperialClient::DUMMY_SECRET}!!" }
      let(:incorrect_consumer_credentials) {{ :consumer_key => ImperialClient::DUMMY_KEY, :consumer_secret => incorrect_secret }}
      let(:invalid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:get, test_uri, {}, incorrect_consumer_credentials).to_s }}
      let(:resp) { mock_request.get(test_uri, invalid_auth_header) }
      let(:client_with_correct_credentials) { ImperialClient.new(ImperialClient::DUMMY_KEY, ImperialClient::DUMMY_SECRET) }

      before { ImperialClient.stub(:find_by_consumer_key).and_return(client_with_correct_credentials) }

      it('returns a status of 401') { resp.status.should == 401 }

      it "notifies the client that they have failed at thwarting the Imperials" do
        resp.body.should == "Unauthorized. You are part of the Rebel Alliance and a Trader!"
      end

    end


    context 'client makes request with sufficient and correct OAuth header' do

      let(:test_uri) { "http://example.com" }
      let(:consumer_credentials) {{ :consumer_key => ImperialClient::DUMMY_KEY, :consumer_secret => ImperialClient::DUMMY_SECRET }}
      let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:get, test_uri, {}, consumer_credentials).to_s }}

      context "GET without params" do

        let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:get, test_uri, {}, consumer_credentials).to_s }}

        it 'has a successful response' do
          resp = mock_request.get(test_uri, valid_auth_header)
          resp.status.should == 200
        end

      end

      context "GET with params" do

        let(:uri_with_params) { "#{test_uri}?foo=bar" }
        let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:get, uri_with_params, {}, consumer_credentials).to_s }}

        it 'has a successful response' do
          resp = mock_request.get(uri_with_params, valid_auth_header)
          resp.status.should == 200
        end

      end

      context "POST without params" do

        let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:post, test_uri, {}, consumer_credentials).to_s }}

        it 'has a successful response' do
          resp = mock_request.post(test_uri, valid_auth_header)
          resp.status.should == 200
        end

      end

      context "POST with params" do
        context "Content-Type is x-www-form-urlencoded" do

          let(:form_data) {{ :foo => "bar" }}
          let(:post_data) {{ :content_type => "application/x-www-form-urlencoded", :params => form_data}}
          let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:post, test_uri, form_data, consumer_credentials).to_s }}

          it 'has a successful response' do
            resp = mock_request.post(test_uri, valid_auth_header.merge(post_data))
            resp.status.should == 200
          end

        end

        context "Content-Type is anything other than x-www-form-urlencoded" do

          let(:json_data) {{ :foo => "bar"}.to_json }
          let(:post_data) {{ "CONTENT_TYPE" => "application/json", :input => json_data }}
          let(:valid_auth_header) {{ "HTTP_AUTHORIZATION" => SimpleOAuth::Header.new(:post, test_uri, {}, consumer_credentials).to_s }}

          it 'has a successful response' do
            resp = mock_request.post(test_uri, valid_auth_header.merge(post_data))
            resp.status.should == 200
          end

        end
      end
    end
  end
end

