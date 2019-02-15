module Json::Tools
  # Exception raised by `Json::Tools::Pointer` if the pointer cannot be constructed of evaluated.
  class PointerException < Exception
    getter object, index

    def initialize(@object : JSON::Any, @index : String | Int32)
      super "Unable to access element #{@index} of #{@object}"
    end
  end

  # Exception raised by `Json::Tools::Patch` if the patch document is invalid.
  class IvalidFormat < Exception
    def initialize(object : JSON::Any)
      initialize "JSON object is not an array: #{object}"
    end

    def initialize(message : String)
      super message
    end
  end

  # Exception raised by `Json::Tools::Patch` if a path specified in the operation refers to an array index and is not within the array bounds.
  class OutOfBoundsException < Exception
    getter object, index

    def initialize(@object : Array(JSON::Any), @index : Int32) forall T
      super "Index #{@index} of #{@object} is out of bounds"
    end
  end

  # Exception raised by `Json::Tools::Patch` when trying to remove a property that does not exist in the target JSON object.
  class MissingPropertyException < Exception
    getter object, property_name

    def initialize(@object : JSON::Any, @property_name : String) forall T
      super "Property #{@property_name} of #{@object} is unknown"
    end
  end

  # Exception raised if trying to perform an operation that does not make sense in the current context, for example
  # when trying to access the parent pointer of the root element.
  class IllegalOperationException < Exception
    def initialize(message : String)
      super message
    end
  end

  # Exception raised by `Json::Tools::Patch` when a test operation does not pass.
  class FailedTestException < Exception
    getter value, path

    def initialize(@value : JSON::Any, @path : String)
      super "Expected #{@value} at #{@path}"
    end
  end
end
