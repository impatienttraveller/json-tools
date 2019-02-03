require "json"

module Json::Tools
  # Allowed attributes of a JSON patch object
  OP    = "op"
  PATH  = "path"
  FROM  = "from"
  VALUE = "value"

  # Set of operations as per the RFC
  OP_TEST    = "test"
  OP_REMOVE  = "remove"
  OP_ADD     = "add"
  OP_REPLACE = "replace"
  OP_MOVE    = "move"
  OP_COPY    = "copy"

  # An implementatition of https://datatracker.ietf.org/doc/rfc6902
  #
  # This class represent a JSON patch object that can be applied to another JSON object, simply pass the patch object upon construction and then apply on the target document:
  #
  # ```
  # json_patch = JSON.parse ...
  # json_obj = JSON.parse ...
  # patch = Json::Tools::Patch.new(json_patch)
  # patched_obj = patch.apply(json_obj)
  # ```
  class Patch
    def initialize(@patch : JSON::Any)
      raise IvalidFormat.new(@patch) unless @patch.as_a?
    end

    # Applies this patch on the given JSON object.
    #
    # ```
    # json_patch = JSON.parse(<<-JSON
    #   [
    #     { "op": "add", "path": "/n", "value": [1, 2, 3] },
    #     { "op": "remove", "path": "/a" },
    #     { "op": "replace", "path": "/c/1", "value": "new" }
    #   ]
    #   JSON
    # )
    # json_obj = JSON.parse(<<-JSON
    #   {
    #     "a": "a val",
    #     "b": 123,
    #     "c": ["first", "old", "last"]
    #   }
    #   JSON
    # )
    # patch = Json::Tools::Patch.new(json_patch)
    # patched_obj = patch.apply(json_obj) # => { "b": 123, "c": ["first", "new", "last"], "n": [1, 2, 3] }
    # ```
    def apply(document : JSON::Any)
      doc = document.clone
      @patch.as_a.each { |e|
        case e[OP]?
        when OP_TEST
          test(doc, string_element(e, PATH), json_element(e, VALUE))
        when OP_REMOVE
          remove(doc, string_element(e, PATH))
        when OP_ADD
          add(doc, string_element(e, PATH), json_element(e, VALUE))
        when OP_REPLACE
          replace(doc, string_element(e, PATH), json_element(e, VALUE))
        when OP_MOVE
          move(doc, string_element(e, FROM), string_element(e, PATH))
        when OP_COPY
          copy(doc, string_element(e, FROM), string_element(e, PATH))
        else
          raise IvalidFormat.new("Invalid operation in element #{e}")
        end
      }
      return doc
    end

    private def string_element(element : JSON::Any, attribute : String)
      value = element[attribute]?
      raise IvalidFormat.new("Attribute #{attribute} not found in element #{element}") if value.nil?
      raise IvalidFormat.new("Attribute #{attribute} of element #{element} is not a string") unless value.as_s?
      return value.as_s
    end

    private def json_element(element : JSON::Any, attribute : String)
      value = element[attribute]?
      raise IvalidFormat.new("Attribute #{attribute} not found in element #{element}") if value.nil?
      return value
    end

    private def test(document : JSON::Any, path : String, value : JSON::Any)
      expected = Pointer.new(path).eval(document)

      unless expected === value
        raise FailedTestException.new(value, path)
      end
      return document
    end

    private def remove(document : JSON::Any, path : String)
      path_pointer = Pointer.new(path)
      parent = path_pointer.parent.eval(document)
      if array = parent.as_a?
        index = get_index(document, path_pointer)
        raise OutOfBoundsException.new(array, index) unless index < array.size
        array.delete_at(index)
      elsif hash = parent.as_h?
        raise MissingPropertyException.new(parent, path_pointer.key) unless hash.delete(path_pointer.key)
      else
        # Can this ever happen?
        raise IllegalOperationException.new("Unexpected parent type: #{parent}")
      end
      return document
    end

    private def add(document : JSON::Any, path : String, value : JSON::Any)
      path_pointer = Pointer.new(path)
      parent = path_pointer.parent.eval(document)
      if array = parent.as_a?
        index = get_index(document, path_pointer)
        raise OutOfBoundsException.new(array, index) unless index <= array.size
        array.insert(index, value)
      elsif hash = parent.as_h?
        hash[path_pointer.key] = value
      else
        # Can this ever happen?
        raise IllegalOperationException.new("Unexpected parent type: #{parent}")
      end
      return document
    end

    private def replace(document : JSON::Any, path : String, value : JSON::Any)
      path_pointer = Pointer.new(path)
      # Ensure the element exists
      path_pointer.eval(document)
      parent = path_pointer.parent.eval(document)
      if array = parent.as_a?
        index = get_index(document, path_pointer)
        raise OutOfBoundsException.new(array, index) unless index < array.size
        array[index] = value
      elsif hash = parent.as_h?
        hash[path_pointer.key] = value
      else
        # Can this ever happen?
        raise IllegalOperationException.new("Unexpected parent type: #{parent}")
      end
      return document
    end

    private def move(document : JSON::Any, from : String, path : String)
      value_to_move = Pointer.new(from).eval(document)
      remove(document, from)
      return add(document, path, value_to_move)
    end

    private def copy(document : JSON::Any, from : String, path : String)
      value_to_copy = Pointer.new(from).eval(document)
      return add(document, path, value_to_copy)
    end

    private def get_index(document : JSON::Any, pointer : Pointer)
      index = pointer.key.to_i?
      raise PointerException.new(document, pointer.key) if index.nil?
      return index
    end
  end
end
