module Json::Tools
  class PointerException < Exception
    getter object, index

    def initialize(@object : JSON::Any, @index : String | Int32)
      super "Unable to access element #{@index} of #{@object}"
    end
  end

  class IvalidFormat < Exception
    def initialize(object : JSON::Any)
      initialize "JSON object is not an array: #{object}"
    end

    def initialize(message : String)
      super message
    end
  end

  class OutOfBoundsException < Exception
    getter object, index

    def initialize(@object : Array(JSON::Any), @index : Int32) forall T
      super "Index #{@index} of #{@object} is out of bounds"
    end
  end

  class MissingPropertyException < Exception
    getter object, property_name

    def initialize(@object : JSON::Any, @property_name : String) forall T
      super "Property #{@property_name} of #{@object} is unknown"
    end
  end

  class IllegalOperationException < Exception
    def initialize(message : String)
      super message
    end
  end

  class FailedTestException < Exception
    getter value, path

    def initialize(@value : JSON::Any, @path : String)
      super "Expected #{@value} at #{@path}"
    end
  end
end
