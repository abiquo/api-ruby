##
# Ruby Abiquo API client
#
require 'abiquo-api/errors.rb'
require 'abiquo-api/httpclient.rb'
require 'abiquo-api/link.rb'
require 'abiquo-api/model.rb'

##
# Main class
#
class AbiquoAPI
  include AbiquoAPIClient

  attr_reader :http_client

  attr_accessor :enterprise
  attr_accessor :user
  attr_accessor :properties
  attr_accessor :version

  ##
  # Constructor. Accepts a hash of options.
  #
  # Required options:
  #   :abiquo_api_url:: The URL of the Abiquo API. ie. https://yourserver/api
  #   :abiquo_username:: The username used to connect to the Abiquo API.
  #   :abiquo_password:: The password for your user.
  #
  # Optional:
  #   :version:: The Abiquo API version to include in each request.
  #
  # Returns an instance of the Abiquo API client.
  #
  def initialize(options = {})
    api_url = options[:abiquo_api_url]
    api_username = options[:abiquo_username]
    api_password = options[:abiquo_password]

    raise "Faltan cosas" if api_url.nil? or api_username.nil? or api_password.nil?

    @http_client = AbiquoAPIClient::HTTPClient.new(api_url,
                                                  api_username,
                                                  api_password)
    api_path = URI.parse(api_url).path

    loginresp = @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => "#{api_path}/login",
      :accept   => 'application/vnd.abiquo.user+json'
      )
    @enterprise = AbiquoAPIClient::Link.new(loginresp['links'].select {|l| l['rel'] == 'enterprise'}.first)
    @user = AbiquoAPIClient::LinkModel.new(loginresp.merge({:client => self}))

    @properties = @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => "#{api_path}/config/properties",
      :accept   => 'application/vnd.abiquo.systemproperties+json'
      )

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
  # Returns a new instance of the AbiquoAPIClient::LinkModel class.
  # 
  # Parameters:
  #   A hash of attributes to set in the object.
  #
  def new_object(hash)
    AbiquoAPIClient::LinkModel.new(hash.merge({ :client => self}))
  end

  ##
  # Executes an HTTP GET over the AbiquoAPIClient::Link passed as parameter.
  # 
  # Required parameters:
  #   link:: An instance of an AbiquoAPIClient::Link.
  #
  # Optional parameters:
  #   options:: A hash of key/values that will be sent as query.
  #
  # NOTE. The option :accept will override Accept header sent in
  #       the request.
  #
  # Returns an instance of the AbiquoAPIClient::LinkModel class representing
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

    if resp.is_a? Array
      tmp_a = []
      resp.each do |r|
        tmp_r = AbiquoAPIClient::LinkModel.new(r.merge({:client => self}))
        tmp_a << tmp_r
      end
      tmp_a
    else
      AbiquoAPIClient::LinkModel.new(resp.merge({ :client => self}))
    end
  end

  ##
  # Executes an HTTP POST over the AbiquoAPIClient::Link passed as parameter.
  # 
  # Required parameters:
  #   link:: An instance of an AbiquoAPIClient::Link.
  #   data:: The data to send in the HTTP request. Usually an instance
  #          of the AbiquoAPIClient::LinkModel instance. Will be 
  #          serialized to JSON before sending.
  #
  # Optional parameters:
  #   options:: A hash of key/values that will be sent as query.
  #
  # NOTE. The option :accept and :content options will override Accept 
  #       and Content-Type headers sent in the request.
  #
  # Returns an instance of the AbiquoAPIClient::LinkModel class representing
  # the requested resource or nil if the request returned empty.
  #
  def post(link, data, options = {})
    ctype = options[:content].nil? ? link.type : options.delete(:content)
    accept = options[:accept].nil? ? link.type : options.delete(:accept)

    req_hash = {
      :method   => 'POST',
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
  # Executes an HTTP PUT over the AbiquoAPIClient::Link passed as parameter.
  # 
  # Required parameters:
  #   link:: An instance of an AbiquoAPIClient::Link.
  #   data:: The data to send in the HTTP request. Usually an instance
  #          of the AbiquoAPIClient::LinkModel instance. Will be 
  #          serialized to JSON before sending.
  #
  # Optional parameters:
  #   options:: A hash of key/values that will be sent as query.
  #
  # NOTE. The option :accept and :content options will override Accept 
  #       and Content-Type headers sent in the request.
  #
  # Returns an instance of the AbiquoAPIClient::LinkModel class representing
  # the requested resource or nil if the request returned empty.
  #
  def put(link, data, options = {})
    ctype = options[:content].nil? ? link.type : options.delete(:content)
    accept = options[:accept].nil? ? link.type : options.delete(:accept)

    req_hash = {
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
  # Executes an HTTP DELETE over the AbiquoAPIClient::Link passed as parameter.
  # 
  # Required parameters:
  #   link:: An instance of an AbiquoAPIClient::Link.
  #
  # Optional parameters:
  #   options:: A hash of key/values that will be sent as query.
  #
  # Returns nil
  #
  def delete(link, options = {})
    @http_client.request(
      :expects  => [204],
      :method   => 'DELETE',
      :path     => link.href
    )
    nil
  end
end
