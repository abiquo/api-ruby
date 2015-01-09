require 'abiquo-api/errors.rb'
require 'abiquo-api/httpclient.rb'
require 'abiquo-api/link.rb'
require 'abiquo-api/model.rb'

class AbiquoAPI
  include AbiquoAPIClient

  attr_reader :http_client

  attr_accessor :enterprise
  attr_accessor :user
  attr_accessor :properties
  attr_accessor :version

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
  
  def new_object(hash)
    AbiquoAPIClient::LinkModel.new(hash.merge({ :client => self}))
  end

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

  def delete(link, options = {})
    @http_client.request(
      :expects  => [204],
      :method   => 'DELETE',
      :path     => link.href
    )
    nil
  end
end
