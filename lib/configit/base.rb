require 'erb'
require 'yaml'

module Configit
  # The base class the custom configuration classes should derive from.
  # 
  # === Example
  #
  #   class FooConfig < Configit::Base
  #     attribute :name, "The name of the user", :required => true
  #     attribute :port, :required => true, :type => :integer, :default => 80
  #     attribute :log_level, :type => :symbol, :default => :debug
  #   end
  class Base
    @@converters ||= {
      :string  => lambda {|v| v.to_s},
      :integer => lambda {|v| v.to_i},
      :float   => lambda {|v| v.to_f},
      :symbol  => lambda {|v| v.to_sym}
    }

    # Returns the attributes defined for this class.
    def attributes
      @attributes ||= {}
    end

    def errors
      @errors ||= []
    end

    def clear_errors
      @errors = []
    end

    # Returns true if there are no errors, false otherwise
    def valid?
      errors.empty?
    end

    class << self
      # Returns a hash of Configit::AttributeDefinition's keyed by attribute name.
      def schema
        @schema ||= {}
      end

      def evaluate_erb=(value)
        raise ArgumentError unless value == true || value == false
        @evaluate_erb = value
      end

      # Loads the config from a YAML string.
      # 
      # Unrecognized attributes are placed into the errors list.
      def load_from_string(string)
        config = self.new
        string = ERB.new(string).result unless @evaluate_erb == false
        YAML.load(string).each do |key,value|
          key = key.to_sym
          if schema.has_key?(key)
            config.attributes[key] = value
          else
            config.errors << "#{key} is not a valid attribute"
          end
        end
        return config
      end

      def load_from_file(filename)
        raise ArgumentError, "File #{filename} does not exist"  unless File.exists?(filename)
        raise ArgumentError, "File #{filename} is not readable" unless File.readable?(filename)

        return load_from_string(IO.read(filename))
      end

      # Defines a new attribute on the config.
      # 
      # The first argument should be the name of the attribute.
      # 
      # If the next argument is a string it will be interpreted as the
      # description of the argument.
      #
      # The last argument should be a valid options hash.
      #
      # === Valid options
      #
      # [:required]
      #   Determines if the option is required or not. Should be either
      #   true or false
      # [:type]
      #   The type of the attribute. Should be one of :integer, :string
      #   :symbol, :float
      def attribute(name, desc=nil, options={})
        raise AttributeAlreadyDefined, name if schema.has_key? name
        
        if options == {} && Hash === desc
          options = desc
          desc = nil
        end

        attr = AttributeDefinition.new(name, desc, options)
        schema[name] = attr

        define_method name do
          value = attributes[name]
          @@converters[attr.type].call(value)
        end

        define_method "#{name}=" do |value| 
          attributes[name] = value
          value
        end

        return attr
      end
    end
  end
end
