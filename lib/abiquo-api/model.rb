require 'formatador'

module AbiquoAPIClient
  ##
  # Represents a resource in the Abiquo API.
  #
  class LinkModel
    ##
    # Constructor
    #
    # Accepts a hash of key values representing the resource, plus
    # an instance of the AbiquoAPI class to be used to execute
    # the HTTP requests, specified as the :client attribute.
    #
    def initialize(attrs={})
      raise "Needs a connection!" if attrs[:client].nil? 
      @client = attrs.delete(:client)

      attributes = Hash[attrs.clone.map {|k, v| [k.to_s, v ] }]
      
      if not attributes['links'].nil?
        links = []

        attributes['links'].each do |link|
          link = link.to_hash if link.is_a? AbiquoAPIClient::Link
          new_lnk = {}

          if 'edit'.eql?(link['rel']) or 'self'.eql?(link['rel'])
            # Create a URL string attribute
            rel = 'url'
            create_attr(rel, true)
            instance_variable_set("@#{rel}", link['href'])
          end

          # Create new getters and setters
          # Also sets value to a Link object
          rel = "#{link['rel'].gsub(/\//, '_')}"
          new_lnk[rel.to_sym] = Link.new(link.merge({:client => @client}))
          links << new_lnk
          
          # For every link that points to an ID
          # create a getter
          if link['href'].split('/').last.is_a? Integer
            idrel = "#{link['rel'].gsub(/\//, '_')}_id"
            create_attr(idrel, true)
            instance_variable_set("@#{idrel}", link['href'].split('/').last.to_i)
          end
        end
        attributes.delete('links')

        create_attr("links")
        instance_variable_set("@links", links)
        
        # Now create getters and setters for every method
        attributes.keys.each do |k|
          create_attr(k)
          instance_variable_set("@#{k}", attributes[k])
        end
      end
    end

    ##
    # Serializes the object into a valid JSON for the Abiquo API.
    #
    def to_json
      att = self.instance_variables.map {|v| v.to_s }
      links = []
      data = {}

      att.delete("@url")
      att.delete("@client")

      self.links.each do |l|
        links << l.values.first.to_hash
      end
      att.delete("@links")

      att.each do |opt|
        data[opt.delete("@")] = instance_variable_get(opt)
      end
      data['links'] = links
      data.to_json
    end

    ##
    # Pretty print an instance object.
    #
    def inspect
      Thread.current[:formatador] ||= Formatador.new
      data = "#{Thread.current[:formatador].indentation}<#{self.class.name}"
      Thread.current[:formatador].indent do
        unless self.instance_variables.empty?
          vars = self.instance_variables.clone
          vars.delete(:@client)
          data << "\n"
          data << vars.map { |v| "#{v}=#{instance_variable_get(v.to_s).inspect}" }.join(",\n#{Thread.current[:formatador].indentation}")
        end
      end
      data << "\n#{Thread.current[:formatador].indentation}>"
      data
    end

    ##
    # Returns an array of {AbiquoAPI::Link} for the resource
    #
    def links
      self.links.map {|l| l.values }.flatten
    end

    ##
    # Retrieves the link that has the 'rel' attribute specified
    # as parameter.
    #
    # Parameters:
    # [link_rel]  The 'rel' value to look for, symbolized.
    #
    # Returns the first link found with the 'rel' attribute 
    # specified or nil if not found.
    #
    def link(link_rel)
      self.links.select {|l| l[link_rel] }.first[link_rel]
    end

    ##
    # Checks if the object has a link with the 'rel' attribute
    # specified as parameter.
    #
    # Parameters:
    # [link_rel]  The 'rel' value to look for, symbolized.
    #
    # Returns the true if the object has a link with the 
    # specified 'rel' or false otherwhise.
    #
    def has_link?(link_rel)
      c = self.links.select {|l| l[link_rel] }.count
      c == 0 ? false : true
    end

    ##
    # Executes an HTTP PUT over the resource in Abiquo API,
    # sending the current attributes as data.
    #
    # Returns a new instance representing the updated resource.
    #
    def update(options = {})
      @client.put(self.link(:edit), self, options)
    end

    ##
    # Executes an HTTP DELETE over the resource in Abiquo API,
    # deleting the current resource.
    #
    # Returns nil on success.
    #
    def delete(options = {})
      @client.delete(self.link(:edit), options)
    end

    ##
    # Executes an HTTP GET over the resource in Abiquo API.
    #
    # Returns a new instance representing resource.
    #
    def refresh(options = {})
      self.link(:edit).get
    end

    private

    ##
    # Creates a new method in the instance object.
    #
    # Parameters:
    # [name]    The name of the method to be created.
    # [&block]  The block of code for that method.
    #
    def create_method( name, &block )
      self.class.send( :define_method, name, &block )
    end

    ##
    # Creates a new attribute for the instance object.
    #
    # Parameters:
    # [name]  The name of the attribute to be created.
    # [ro]    Boolean that specifies if the attribute will
    #         read only or read write. Defaults to false (rw)
    #
    def create_attr( name , ro = false)
      unless ro
        create_method( "#{name}=".to_sym ) { |val| 
          instance_variable_set( "@" + name, val)
        }
      end

      create_method( name.to_sym ) { 
        instance_variable_get( "@" + name )
      }
    end
  end
end
