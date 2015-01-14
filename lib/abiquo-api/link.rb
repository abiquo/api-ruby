require 'formatador'

module AbiquoAPIClient
  ##
  # Represents a link on the Abiquo API.
  #
  class Link
    ##
    # The target URL of the link
    #
    attr_accessor :href
    ##
    # The 'rel' attribute of the link
    #
    attr_accessor :rel
    ##
    # The title of the link
    #
    attr_accessor :title
    ##
    # The media type of the link
    #
    attr_accessor :type

    ##
    # Constructor.
    #
    # Accepts a hash reprsenting a link, usually returned
    # after parsing the JSON response.
    #
    # If the hash contains :client key, the value will be used
    # as an {AbiquoAPI} client allowing the get method to retrieve
    # the target resource.
    #
    def initialize(hash)
      @client = hash.delete(:client) if hash.keys.include?(:client)

      h = Hash[hash.map {|k, v| [k.to_sym, v ] }]

      @href = h[:href].nil? ? '' : h[:href]
      @rel = h[:rel].nil? ? '' : h[:rel]
      @title = h[:title].nil? ? '' : h[:title]
      @type = h[:type].nil? ? '' : h[:type]
    end

    ##
    # If the :client attribute is not nil, will retrieve
    # the resource that this link represents, or nil otherwise
    #
    def get
      if @client.nil?
        return nil
      else
        @client.get(self)
      end
    end

    ##
    # Converts an instance to its hash form, so it can be
    # serialized as JSON.
    #
    def to_hash
      h = self.href.nil? ? '' : self.href
      r = self.rel.nil? ? '' : self.rel
      t = self.title.nil? ? '' : self.title
      y = self.type.nil? ? '' : self.type

      { 
        "href"  => h,
        "type"  => y,
        "rel"   => r,
        "title" => t
      }
    end

    ##
    # Pretty print the object.
    #
    def inspect
      Thread.current[:formatador] ||= Formatador.new
      data = "#{Thread.current[:formatador].indentation}<#{self.class.name}"
      Thread.current[:formatador].indent do
        unless self.instance_variables.empty?
          vars = self.instance_variables.clone
          vars.delete(:@client)
          data << " "
          data << vars.map { |v| "#{v}=#{instance_variable_get(v.to_s).inspect}" }.join(", ")
        end
      end
      data << " >"
      data
    end
  end
end