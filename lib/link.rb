module AbiquoAPIClient
  class Link
    attr_accessor :href
    attr_accessor :rel
    attr_accessor :title
    attr_accessor :type

    def initialize(hash)
      h = Hash[hash.map {|k, v| [k.to_sym, v ] }]

      @href = h[:href].nil? ? '' : h[:href]
      @rel = h[:rel].nil? ? '' : h[:rel]
      @title = h[:title].nil? ? '' : h[:title]
      @type = h[:type].nil? ? '' : h[:type]
    end
  end
end