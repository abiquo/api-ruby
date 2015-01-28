require 'formatador'

module AbiquoAPIClient
  ##
  # Represents a collection of resources in the Abiquo API.
  #
  class LinkCollection
    def initialize(parsed_response, type, client)
      @size = parsed_response['totalSize'].nil? ? parsed_response['collection'].count : parsed_response['totalSize']
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
        @next = @links.select {|l| l['rel'].eql? "next" }.first
      end

      @collection = parsed_response['collection'].map {|r| client.new_object(r)}
      
      @client = client
    end

    ##
    # Returns the total size of the collection
    #
    def size
      @size
    end
    alias count size

    ##
    # Returns the first element in the collection
    #
    def first(count = nil)
      if count.nil?
        @collection.first
      else
        out = []
        @collection.first(count).each do |item|
          out << item
        end
        out
      end
    end

    ##
    # Returns the last element in the collection
    #
    def last
      out = nil

      each {|i| out = i }
      
      out
    end

    ##
    # Returns an array representing the collection
    #
    def to_a
      out = []

      each { |e| out << e }

      out
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
          if i > @collection.count - 1 and i < @size
            q = URI.parse(@next['href']).query.split('&').map {|it| it.split('=') }
            opts = Hash[q.map{ |k, v| [k.to_sym, v] }]

            l = AbiquoAPIClient::Link.new(:href => @next['href'],
                                          :type => @type)
            resp = @client.get(l, opts)
            @next = resp['links'].select {|li| li['rel'] == 'next' }.first

            items = resp['collection'].map {|e| @client.new_object(e) }
            @collection.concat(items)
          end

          yield @collection[i]
        end
      else
        self.to_enum
      end
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
