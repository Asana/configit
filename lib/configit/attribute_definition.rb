module Configit
  # The definition of an attribute in a config.
  class AttributeDefinition
    attr_reader :name
    attr_reader :desc
    attr_reader :default
    attr_reader :type
    
    # See Configit::Base.attribute
    def initialize(name, desc, options={})
      # Clone them so we can delete from the hash
      options = options.clone

      raise ArgumentError, "Name must be a symbol" if not Symbol === name

      @name = name
      @desc = desc
      @required = options.delete(:required) || false
      @type = options.delete(:type) || :string
      @default = options.delete(:default)

      if options.any?
        raise ArgumentError, "Invalid options #{options.keys.join(',')}"
      end
    end

    def required?
      @required
    end
  
    # Returns an error string if the value is not valid per this AttributeDefinition
    def validate(value)
      if required? && (value == nil || value == "") && (default == nil || default == "")
        return "#{name} is a required attribute"
      end
      # TODO: add type validation here
      nil
    end
  end
end
