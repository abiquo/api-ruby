require 'abiquo-api/collection'
require 'abiquo-api/errors'
require 'abiquo-api/httpclient'
require 'abiquo-api/link'
require 'abiquo-api/model'

##
# Ruby Abiquo API client main class
#
class AbiquoAPI
  include AbiquoAPIClient

  ##
  # The {AbiquoAPIClient::HTTPClient} used by
  # this instance.
  #
  attr_reader :http_client

  ##
  # A hash of the enterprise to which the user
  # belongs to.
  #
  attr_accessor :enterprise

  ##
  # An instance of {AbiquoAPIClient::LinkModel} representing
  # the current user.
  #
  attr_accessor :user

  ##
  # The Abiquo API version used by this client.
  #
  attr_accessor :version

  ##
  # Initializes a new AbiquoAPI instance.
  #
  # Required options:
  #
  #   :abiquo_api_url     => The URL of the Abiquo API. ie. https://yourserver/api
  #   :abiquo_username    => The username used to connect to the Abiquo API.
  #   :abiquo_password    => The password for your user.
  #   :version            => The Abiquo API version to include in each request.
  #                          Defaults to whatever is returned in the /api/version resource
  #   :connection_options => Excon HTTP client connection options.
  #                          { :connect_timeout => <time_in_secs>,
  #                            :read_timeout => <time_in_secs>,
  #                            :write_timeout => <time_in_secs>,
  #                            :ssl_verify_peer => <true_or_false>,
  #                            :ssl_ca_path => <path_to_ca_file> }
  #
  def initialize(options = {})
    api_url = options[:abiquo_api_url]
    api_username = options[:abiquo_username]
    api_password = options[:abiquo_password]
    api_key = options[:abiquo_api_key]
    api_secret = options[:abiquo_api_secret]
    token_key = options[:abiquo_token_key]
    token_secret = options[:abiquo_token_secret]
    connection_options = options[:connection_options] || {}

    raise "You need to set :abiquo_api_url" if api_url.nil?
    raise "You need to provide either basic auth or oauth credentials!!" if (api_username.nil? or api_password.nil?) and 
          (api_key.nil? or api_secret.nil? or token_key.nil? or token_secret.nil?)

    unless api_key.nil?
      credentials = {
        :consumer_key => api_key,
        :consumer_secret => api_secret,
        :token => token_key,
        :token_secret => token_secret
      }
    else
      credentials = {
        :api_username => api_username,
        :api_password => api_password
      }
    end

    @http_client = AbiquoAPIClient::HTTPClient.new(api_url,
                                                  credentials,
                                                  connection_options)

    api_path = URI.parse(api_url).path

    loginresp = @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => "#{api_path}/login",
      :accept   => 'application/vnd.abiquo.user+json'
      )
    @enterprise = AbiquoAPIClient::Link.new(loginresp['links'].select {|l| l['rel'] == 'enterprise'}.first)
    @user = AbiquoAPIClient::LinkModel.new(loginresp.merge({:client => self}))

    if options.has_key? :version
      @version = options[:version][0..2]
    else
      @version = @http_client.request(
            :expects  => [200],
            :method   => 'GET',
            :path     => "#{api_path}/version",
            :accept   => 'text/plain'
      ).delete("\n")[0..2]
    end

    self
  end

  ##
  # Loads System properties
  #
  def properties
    @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => "#{api_path}/config/properties",
      :accept   => 'application/vnd.abiquo.systemproperties+json'
    )
  end
  
  ##
  # Returns a new instance of the {AbiquoAPIClient::LinkModel} class.
  # 
  # Parameters:
  #   A hash of attributes to set in the object.
  #
  def new_object(hash)
    AbiquoAPIClient::LinkModel.new(hash.merge({ :client => self}))
  end

  ##
  # Returns a new instance of the {AbiquoAPIClient::LinkCollection} 
  # class.
  # 
  # Parameters:
  #   An instance of {AbiquoAPIClient::Link} pointing to the URL of 
  #   the collection.
  #
  def list(link, options = {})
    AbiquoAPI::LinkCollection.new(self.get(link, options), link.type, self)
  end

  ##
  # Executes an HTTP GET over the {AbiquoAPIClient::Link} passed as parameter.
  # 
  # Required parameters:
  # [link]   An instance 
  #          of an {AbiquoAPIClient::Link}.
  #
  # Optional parameters:
  # [options]   A hash of key/values that will 
  #             be sent as query.
  #
  # **NOTE:** The option :accept will override Accept header sent in
  # the request.
  #
  # Returns an instance of the {AbiquoAPIClient::LinkModel} class representing
  # the requested resource.
  #
  def get(link, options = {})
    accept = options[:accept].nil? ? link.type : options.delete(:accept)

    req_hash = {
      :expects  => [200],
      :method   => 'GET',
      :path     => link.href,
      :query    => options
    }

    req_hash[:accept] = "#{accept}; version=#{@version};" unless accept.eql? ""
    resp = @http_client.request(req_hash)

    if resp['collection'].nil?
      AbiquoAPIClient::LinkModel.new(resp.merge({ :client => self}))
    else
      resp
    end
  end

  ##
  # Executes an HTTP POST over the {AbiquoAPIClient::Link} passed as parameter.
  # 
  # Required parameters:
  # [link]   An instance of an {AbiquoAPIClient::Link}.
  # [data]   The data to send in the HTTP request. Usually an instance
  #          of the {AbiquoAPIClient::LinkModel} instance. Will be 
  #          serialized to JSON before sending.
  #
  # Optional parameters:
  # [options]   A hash of key/values that will be sent as query.
  #
  # **NOTE:** The option :accept and :content options will override Accept 
  # and Content-Type headers sent in the request.
  #
  # Returns an instance of the {AbiquoAPIClient::LinkModel} class representing
  # the requested resource or nil if the request returned empty.
  #
  def post(link, data, options = {})
    ctype = options[:content].nil? ? link.type : options.delete(:content)
    accept = options[:accept].nil? ? link.type : options.delete(:accept)

    data = data.to_json if data.respond_to?('to_json')

    req_hash = {
      :expects  => [200, 201, 202, 204],
      :method   => 'POST',
      :path     => link.href,
      :body     => data,
      :query    => options
    }

    req_hash[:accept] = "#{accept}; version=#{@version};" unless accept.eql? ""
    req_hash[:content] = "#{ctype}; version=#{@version};" unless ctype.eql? ""

    resp = @http_client.request(req_hash)
    resp.nil? ? nil : AbiquoAPIClient::LinkModel.new({ :client => self}.merge(resp))
  end

  ##
  # Executes an HTTP PUT over the {AbiquoAPIClient::Link} passed as parameter.
  # 
  # Required parameters:
  # [link]     An instance of an {AbiquoAPIClient::Link}.
  # [data]     The data to send in the HTTP request. Usually an instance
  #            of the {AbiquoAPIClient::LinkModel} instance. Will be 
  #            serialized to JSON before sending.
  #
  # Optional parameters:
  # [options]  A hash of key/values that will be sent as query.
  #
  # **NOTE:** The option :accept and :content options will override Accept 
  # and Content-Type headers sent in the request.
  #
  # Returns an instance of the {AbiquoAPIClient::LinkModel} class representing
  # the requested resource or nil if the request returned empty.
  #
  def put(link, data, options = {})
    ctype = options[:content].nil? ? link.type : options.delete(:content)
    accept = options[:accept].nil? ? link.type : options.delete(:accept)

    req_hash = {
      :expects  => [200, 201, 202, 204],
      :method   => 'PUT',
      :path     => link.href,
      :body     => data.to_json,
      :query    => options
    }

    req_hash[:accept] = "#{accept}; version=#{@version};" unless accept.eql? ""
    req_hash[:content] = "#{ctype}; version=#{@version};" unless ctype.eql? ""

    resp = @http_client.request(req_hash)
    resp.nil? ? nil : AbiquoAPIClient::LinkModel.new({ :client => self}.merge(resp))
  end

  ##
  # Executes an HTTP DELETE over the {AbiquoAPIClient::Link} passed as parameter.
  # 
  # Required parameters:
  # [link]     An instance of an {AbiquoAPIClient::Link}.
  #
  # Optional parameters:
  # [options]  A hash of key/values that will be sent as query.
  #
  # Returns nil
  #
  def delete(link, options = {})
    @http_client.request(
      :expects  => [204],
      :method   => 'DELETE',
      :path     => link.href,
      :query    => options
    )
    nil
  end
end
