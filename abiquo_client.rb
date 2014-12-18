require './lib/httpclient.rb'
require './lib/link.rb'
require './lib/model.rb'

class AbiquoClient
  include AbiquoAPIClient

  attr_reader :http_client

  attr_accessor :enterprise
  attr_accessor :user
  attr_accessor :properties

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
    @enterprise = loginresp['links'].select {|l| l['rel'] == 'enterprise'}.first
    @user = loginresp

    @properties = @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => "#{api_path}/config/properties",
      :accept   => 'application/vnd.abiquo.systemproperties+json'
      )

    self
  end

  def get(link, options = {})
    resp = @http_client.request(
      :expects  => [200],
      :method   => 'GET',
      :path     => link.href,
      :accept   => link.type
    )

    if resp.is_a? Array
      tmp_a = []
      resp.each do |r|
        tmp_r = AbiquoClient::LinkModel.new(r.merge({:client => self}))
        tmp_a << tmp_r
      end
      tmp_a
    else
      AbiquoClient::LinkModel.new(resp.merge({ :client => self}))
    end
  end

  def post(link, data, options = {})
    @http_client.request(
      :expects  => [201, 202],
      :method   => 'POST',
      :path     => link.href,
      :accept   => link.type,
      :content  => link.type,
      :body     => data.to_json,
      :query    => options
    )
  end

  def put()
    AbiquoClient::LinkModel.new(
      @http_client.request(
        :expects  => [201, 202],
        :method   => 'PUT',
        :path     => link.href,
        :accept   => link.type,
        :content  => link.type,
        :body     => data.to_json,
        :query    => options
      )
    )
  end

  def delete(link, options = {})
    @http_client.request(
      :expects  => [204],
      :method   => 'DELETE',
      :path     => link.href
    )
  end
end
