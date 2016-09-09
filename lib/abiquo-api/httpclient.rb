require 'faraday'
require 'faraday_middleware'
require 'excon'
require 'addressable/uri'
require 'json'

module AbiquoAPIClient
  ##
  # HTTPClient class.
  #
  # Does the actual HTTP requests to the server.
  #
  class HTTPClient
    ##
    # Faraday connection object.
    #
    attr_reader :connection

    ##
    # Cookies returned by the API. Contains the auth
    # cookie that will be used after the first call.
    #
    attr_reader :cookies

    ##
    # Constructor. Recieves the parameters to establish
    # a connection to the Abiquo API.
    #
    # Parameters:
    #   :abiquo_api_url:: The URL of the Abiquo API. ie. https://yourserver/api
    #   :creds:: The credentials used to connect to the Abiquo API (basic auth or oauth).
    #   :connection_options:: { :connect_timeout => <time_in_secs>, :read_timeout => <time_in_secs>, :write_timeout => <time_in_secs>,
    #                           :ssl_verify_peer => <true_or_false>, :ssl_ca_path => <path_to_ca_file> }
    #
    def initialize(api_url, creds, connection_options)
      if creds.has_key? :consumer_key
        @connection = Faraday.new(api_url, connection_options) do |c|
          c.request :oauth, creds
          c.adapter :excon
        end
      else
        @connection = Faraday.new(api_url, connection_options ) do |c|
          c.basic_auth(creds[:api_username], creds[:api_password])
          c.adapter :excon
        end
      end

      self
    end

    ##
    # The public method called by the client.
    #
    # Parameters:
    # [params]   A hash of options to be passed to the 
    #            Faraday connection.
    # 
    # Returns a hash resulting of parsing the response
    # body as JSON, or nil if the response is "No 
    # content" (HTTP code 204).
    #
    def request(params)
      # Remove nil params
      params.reject!{|k,v| v.nil?}

      # Setup Accept and Content-Type headers
      headers = {}
      headers.merge!('Accept' => params.delete(:accept)) if params.has_key?(:accept)
      headers.merge!('Content-Type' => params.delete(:content)) if params.has_key?(:content)

      # Set Auth cookie and delete user and password if present
      unless @cookies.nil?
        # @connection.data.delete(:user) unless @connection.data[:user].nil?
        # @connection.data.delete(:password) unless @connection.data[:password].nil?
        headers.merge!(@cookies)
      end
      if params.has_key? :headers
        params[:headers].merge!(headers)
      else
        params[:headers] = headers
      end

      response = issue_request(params)
      return nil if response.nil?
      
      begin
        response = JSON.parse(response.body) unless response.body.empty?
      rescue
        response = response.body
      end
    end

    private

    ##
    # Issues the HTTP request using the Faraday connection
    # object.
    # 
    # Handles API error codes.
    #
    def issue_request(params)
      full_path = Addressable::URI.parse(params[:path])
      if full_path.host.nil?
        # only path
        full_url = Addressable::URI.parse(@connection.url_prefix.to_s + '/' + params[:path].gsub(@connection.url_prefix.path, ""))
      else
        full_url = Addressable::URI.parse(params[:path])
      end
      full_url.query_values = params[:query]

      resp = @connection.run_request(params[:method].downcase.to_sym, 
                                     full_url.to_s,
                                     params[:body],
                                     params[:headers])
      # Save cookies
      # Get all "Set-Cookie" headers and replace them with "Cookie" header.
      @cookies = Hash[resp.headers.select{|k| k.eql? "Set-Cookie" }.map {|k,v| ["Cookie", v] }]

      if resp.status == 204
        nil
      elsif resp.status >= 400 and resp.status <= 600
        unless resp.body.nil?
          begin
            error_response = JSON.parse(resp.body)
            error_code = error_response['collection'][0]['code']
            error_text = error_response['collection'][0]['message']
          rescue JSON::ParserError
            error_code = ''
            error_text = ''
          end
        end
        case resp.status
        when 401
          raise AbiquoAPIClient::InvalidCredentials, "Wrong username or password - #{error_code} - #{error_text}"
        when 403
          raise AbiquoAPIClient::Forbidden, "Not Authorized - #{error_code} - #{error_text}"
        when 406, 400
          raise AbiquoAPIClient::BadRequest, "Bad request - #{error_code} - #{error_text}"
        when 415
          raise AbiquoAPIClient::UnsupportedMediaType, "Unsupported mediatype - #{error_code} - #{error_text}"
        when 404
          raise AbiquoAPIClient::NotFound, "Not Found - #{error_code} - #{error_text}"
        else
          raise AbiquoAPIClient::Error, "#{error.response.body} - #{error_code} - #{error_text}"
        end 
      else
        resp
      end
    end
  end
end