require 'formatador'

module AbiquoAPIClient
  class LinkModel
    def initialize(attrs={})
      raise "Needs a connection!" if attrs[:client].nil? 
      @client = attrs.delete(:client)

      attributes = Hash[attrs.clone.map {|k, v| [k.to_s, v ] }]
      
      if not attributes['links'].nil?
        attributes['links'].each do |link|
          link = link.to_hash if link.is_a? AbiquoAPIClient::Link

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
          instance_variable_set("@#{rel}", Link.new(link.merge({:client => @client})))

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

    def to_json
      att = self.instance_variables.map {|v| v.to_s }
      links = []
      data = {}

      att.delete("@url")
      att.delete("@client")

      att.each do |opt|
        if instance_variable_get(opt).is_a? AbiquoAPIClient::Link
          links << instance_variable_get(opt).to_hash
        else
          data[opt.delete("@")] = instance_variable_get(opt)
        end
      end
      data['links'] = links
      data.to_json
    end

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

    def update
      @client.put(self.edit, self)
    end

    def delete
      @client.delete(self.edit)
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
        instance_variable_get( "@" + name )
      }
    end
  end
end
