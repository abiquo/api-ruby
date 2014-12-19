require 'formatador'

module AbiquoAPIClient
  class Link
    attr_accessor :href
    attr_accessor :rel
    attr_accessor :title
    attr_accessor :type

    def initialize(hash)
      @client = hash.delete(:client) if hash.keys.include?(:client)

      h = Hash[hash.map {|k, v| [k.to_sym, v ] }]

      @href = h[:href].nil? ? '' : h[:href]
      @rel = h[:rel].nil? ? '' : h[:rel]
      @title = h[:title].nil? ? '' : h[:title]
      @type = h[:type].nil? ? '' : h[:type]
    end

    def get
      @client.get(self)
    end

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