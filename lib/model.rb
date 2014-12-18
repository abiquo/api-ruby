require 'formatador'

module AbiquoAPIClient
  class LinkModel
    def initialize(attrs={})
      raise "Needs a connection!" if attrs[:client].nil? 
      @client = attrs.delete(:client)

      attributes = attrs.clone
      
      if not attributes['links'].nil?
        attributes['links'].each do |link|
          if 'edit'.eql?(link['rel']) or 'self'.eql?(link['rel'])
            # Create a URL string attribute
            rel = 'url'
            create_attr(rel, true)
            instance_variable_set("@#{rel}", link['href'])
          end

          # Create new getters and setters
          # Also sets value to a Link object
          rel = "#{link['rel'].gsub(/\//, '_')}"
          create_attr(rel)
          instance_variable_set("@#{rel}", Link.new(link))

          # For every link that points to an ID
          # create a getter
          if link['href'].split('/').last.is_a? Integer
            idrel = "#{link['rel'].gsub(/\//, '_')}_id"
            create_attr(idrel, true)
            instance_variable_set("@#{idrel}", link['href'].split('/').last.to_i)
          end
        end
        attributes.delete('links')

        # Now create getters and setters for every method
        attributes.keys.each do |k|
          create_attr(k)
          instance_variable_set("@#{k}", attributes[k])
        end
      end
    end

    def merge_attributes(new_attributes = {})
      if not new_attributes['links'].nil?
        new_attributes['links'].each do |link|
          rel = "#{link['rel'].gsub(/\//, '_')}_lnk"
          if 'edit'.eql?(link['rel']) or 'self'.eql?(link['rel'])
            rel = 'url'
          end
          new_attributes[rel] = link
        end
      end
      super
    end 

    def to_json
      att = self.attributes.clone
      links = []
      data = {}

      if att.key?(:url)
        urllnk = att.delete(:url)
        urllnk['rel'] = "edit"
        links << urllnk
      end

      att.keys.each do |opt|
        if opt.to_s.include? "_lnk"
          links << att[opt] unless att[opt].nil?
        else
          data[opt.to_s] = att[opt] unless att[opt].nil?
        end
      end
      data['links'] = links
      JSON.parse(data)
    end

    def inspect
      Thread.current[:formatador] ||= Formatador.new
      data = "#{Thread.current[:formatador].indentation}<#{self.class.name}"
      Thread.current[:formatador].indent do
        unless self.instance_variables.empty?
          vars = self.instance_variables.clone
          vars.delete(:@client)
          data << "\n#{Thread.current[:formatador].indentation}"
          data << vars.map { |v| "#{v}=#{instance_variable_get(v.to_s).inspect}" }.join(",\n#{Thread.current[:formatador].indentation}")
        end
      end
      data << "\n#{Thread.current[:formatador].indentation}>"
      data
    end

    private

    def create_method( name, &block )
      self.class.send( :define_method, name, &block )
    end

    def create_attr( name , ro = false)
      unless ro
        create_method( "#{name}=".to_sym ) { |val| 
          instance_variable_set( "@" + name, val)
        }
      end

      create_method( name.to_sym ) { 
        t = instance_variable_get( "@" + name )

        if t.is_a? AbiquoAPIClient::Link
          # If it is a link, let's get it and return it.
          @client.get(t)
        else
          t
        end
      }
    end
  end
end
