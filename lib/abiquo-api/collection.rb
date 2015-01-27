require 'formatador'

module AbiquoAPIClient
  ##
  # Represents a collection of resources in the Abiquo API.
  #
  class LinkCollection
    include Enumerable

    attr_reader :size

    def initialize(parsed_response, type, client)
      @size = parsed_response['totalSize'].nil? ? 0 : parsed_response['totalSize']
      if type.include? ";"
        @type = type.split(';').first
      else
        @type = type
      end
      
      unless parsed_response['links'].empty?
        coluri = URI.parse(parsed_response['links'].first['href'])
        @path = coluri.path

        opts = coluri.query
        opt_hash = opts.split("&").map{|e| { e.split("=").first.to_sym => e.split("=").last }}.reduce({}) {|h,pairs| pairs.each {|k,v| h[k] ||= v}; h}
        @page_size = opt_hash[:limit].to_i
        
        @links = parsed_response['links']
      end

      @collection = parsed_response['collection'].map {|r| client.new_object(r)}
      
      @client = client
    end

    ##
    # Returns the total size of the collection
    #
    def size
      @size || 0
    end

    ##
    # Returns the first element in the collection
    #
    def first(count = nil)
      if count.nil?
        self[0]
      else
        self[0..count]
      end
    end

    ##
    # Returns the last element in the collection
    #
    def last
      self[size() - 1]
    end

    ##
    # Returns an array representing the collection
    #
    def to_a
      @collection[0..(@size - 1)]
    end

    ##
    # Selects elements of the collections for which
    # the supplied block evaluates to true
    #
    def select
      out = []

      each { |e| out << e if yield(e) }

      out
    end

    ##
    # Returns an array resulting of applying the provided
    # block to all of the elements of the collection
    #
    def map
      out = []

      each { |e| out << yield(e) }

      out
    end
    alias collect map

    ##
    # Iterates the collection
    #
    def each
      if block_given?
        (0..@size - 1).each do |i|
          yield self[i]
        end
      else
        self.to_enum
      end
    end

    ##
    # Retrieves the item of the collection at index i
    #
    def [](i)
      if i > @collection.count - 1 and i < @size
        # locate the page where the i-th item is
        page = i / @page_size + 1
        startwith = ( page - 1 ) * @page_size

        l = AbiquoAPIClient::Link.new(:href => @path,
                                      :type => @type)
        resp = @client.get(l, :startwith => startwith, :limit => @page_size)

        items = resp['collection'].map {|e| @client.new_object(e) }
        @collection.concat(items)
      end

      @collection[i]
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
          vars.delete(:@page)
          data << " "
          data << vars.map { |v| "#{v}=#{instance_variable_get(v.to_s).inspect}" }.join(", ")
        end
      end
      data << " >"
      data
    end
  end
end
