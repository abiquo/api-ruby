require 'excon'
require 'uri'
require 'json'

module AbiquoAPIClient
  class HTTPClient
    attr_reader :connection
    attr_reader :auth
    attr_reader :cookies

    def initialize(api_url, api_username, api_password)
      Excon.defaults[:ssl_verify_peer] = false
      @connection = Excon.new(api_url, 
                            :user => api_username, 
                            :password => api_password )
      self
    end

    def request(params)
      # Remove nil params
      params.reject!{|k,v| v.nil?}

      # Setup Accept and Content-Type headers
      headers={}
      headers.merge!('Accept' => params.delete(:accept)) if params.has_key?(:accept)
      headers.merge!('Content-Type' => params.delete(:content)) if params.has_key?(:content)

      # Set Auth cookie and delete user and password if present
      @connection.data.delete(:user) unless @connection.data[:user].nil?
      @connection.data.delete(:password) unless @connection.data[:password].nil?
      headers.merge!(@cookies) unless @cookies.nil?
      
      params[:headers] = headers

      # Correct API path
      path = URI.parse(params[:path]).path
      params[:path] = path
      
      response = issue_request(params)
      response = JSON.parse(response.body) unless response.body.empty?

      # Handle pagination
      if not response['links'].nil? and response['links'].select {|l| l['rel'].eql? "next" }.count > 0
        items = []
        items = items + response['collection'] if not response['collection'].nil?
        
        loop do
          next_url = response['links'].select {|l| l['rel'].eql? "next" }.first['href']
          params[:path] = next_url.gsub!(/^.*#{@api_path}/, "") if next_url.include?(@api_path)
          params[:headers] = headers
          response = issue_request(params)
          response = JSON.parse(response.body) unless response.body.empty?
          items = items + response['collection'] if not response['collection'].nil?
          
          break if response['links'].select {|l| l['rel'].eql? "next" }.count == 0
        end

        items
      else
        if not response['collection'].nil?
          response['collection']
        else
          response.nil? ? nil : response
        end
      end
    end

    private

    def issue_request(options)
      begin
        resp = @connection.request(options)

        # Save cookies
        # Get all "Set-Cookie" headers and replace them with "Cookie" header.
        @cookies = Hash[resp.headers.select{|k| k.eql? "Set-Cookie" }.map {|k,v| ["Cookie", v] }]

        if resp.data['status'] == 204
          nil
        else
          resp
        end
      rescue Excon::Errors::HTTPStatusError => error
        case error.response.status
        when 401
          raise AbiquoClient::InvalidCredentials, "Wrong username or password"
        when 403
          raise AbiquoClient::Forbidden, "Not Authorized"
        when 406
          raise AbiquoClient::BadRequest, "Bad request"
        when 415
          raise AbiquoClient::UnsupportedMediaType, "Unsupported mediatype"
        else
          begin
            error_response = JSON.parse(error.response.body)

            error_code = error_response['collection'][0]['code']
            error_text = error_response['collection'][0]['message']

          rescue
            raise AbiquoClient::Error, error.response.body
          end
          raise AbiquoClient::Error, "#{error_code} - #{error_text}"
        end
      end
    end
  end
end