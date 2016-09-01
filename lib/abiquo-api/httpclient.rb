require 'excon'
require 'uri'
require 'json'

module AbiquoAPIClient
  ##
  # HTTPClient class.
  #
  # Does the actual HTTP requests to the server.
  #
  class HTTPClient
    ##
    # Excon connection object.
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
    #   :abiquo_username:: The username used to connect to the Abiquo API.
    #   :abiquo_password:: The password for your user.
    #   :connection_options:: { :connect_timeout => <time_in_secs>, :read_timeout => <time_in_secs>, :write_timeout => <time_in_secs>,
    #                           :ssl_verify_peer => <true_or_false>, :ssl_ca_path => <path_to_ca_file> }
    #
    def initialize(api_url, api_username, api_password, connection_options)
      Excon.defaults[:ssl_ca_path] = connection_options[:ssl_ca_path] || ''
      Excon.defaults[:ssl_verify_peer] = connection_options[:ssl_verify_peer] || false

      connect_timeout  = connection_options[:connect_timeout] || 60
      read_timeout = connection_options[:read_timeout] || 60
      write_timeout = connection_options[:write_timeout] || 60

      @connection = Excon.new(api_url, 
                            :user => api_username, 
                            :password => api_password,
                            :connect_timeout => connect_timeout,
                            :read_timeout => read_timeout,
                            :write_timeout => write_timeout)

      self
    end

    ##
    # The public method called by the client.
    #
    # Parameters:
    # [params]   A hash of options to be passed to the 
    #            Excon connection.
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
        @connection.data.delete(:user) unless @connection.data[:user].nil?
        @connection.data.delete(:password) unless @connection.data[:password].nil?
        headers.merge!(@cookies)
      end

      params[:headers] = headers

      # Correct API path
      path = URI.parse(params[:path]).path
      params[:path] = path
      
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
    # Issues the HTTP request using the Excon connection
    # object.
    # 
    # Handles API error codes.
    #
    def issue_request(options)
      begin
        options[:headers].merge!(@connection.headers)
        resp = @connection.request(options)

        # Save cookies
        # Get all "Set-Cookie" headers and replace them with "Cookie" header.
        @cookies = Hash[resp.headers.select{|k| k.eql? "Set-Cookie" }.map {|k,v| ["Cookie", v] }]

        if resp.data[:status] == 204
          nil
        else
          resp
        end
      rescue Excon::Errors::HTTPStatusError => error
        case error.response.status
        when 401
          raise AbiquoAPIClient::InvalidCredentials, "Wrong username or password"
        when 403
          raise AbiquoAPIClient::Forbidden, "Not Authorized"
        when 406, 400
          raise AbiquoAPIClient::BadRequest, "Bad request"
        when 415
          raise AbiquoAPIClient::UnsupportedMediaType, "Unsupported mediatype"
        when 404
          begin
            error_response = JSON.parse(error.response.body)

            error_code = error_response['collection'][0]['code']
            error_text = error_response['collection'][0]['message']

          rescue
            raise AbiquoAPIClient::NotFound, "Not Found; #{error_code} - #{error_text}"
          end
          raise AbiquoAPIClient::NotFound, "Not Found"
        else
          begin
            error_response = JSON.parse(error.response.body)

            error_code = error_response['collection'][0]['code']
            error_text = error_response['collection'][0]['message']

          rescue
            raise AbiquoAPIClient::Error, error.response.body
          end
          raise AbiquoAPIClient::Error, "#{error_code} - #{error_text}"
        end
      end
    end
  end
end