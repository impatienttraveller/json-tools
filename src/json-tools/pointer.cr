require "json"

module Json::Tools
  private ESCAPED_CHARS = {
    "^/" => "/",
    "^^" => "^",
    "~0" => "~",
    "~1" => "/",
  }

  # An implementatition of https://tools.ietf.org/html/rfc6901
  #
  # This class represent a JSON pointer that can be evaluated on a JSON object:
  #
  # ```
  # json_obj = JSON.parse ...
  # pointer = Json::Tools::Pointer.new("/foo/0/bar")
  # value = pointer.eval(json_obj)
  # ```
  class Pointer
    @path_parts : Array(String)
    getter path : String

    def initialize(@path)
      @path_parts = Pointer.parse(@path)
    end

    protected def initialize(@path_parts, @path)
    end

    # Returns a pointer to the parent element in the JSON object.
    #
    # ```
    # pointer = Json::Tools::Pointer.new("/foo/0/bar")
    # parent = pointer.parent # => /foo/0
    # ```
    def parent
      raise IllegalOperationException.new("This pointer is the root of the document") if @path_parts.empty? || @path_parts[0].blank?
      parent_parts = @path_parts.clone
      parent_parts.pop
      parent_parts.push("") unless parent_parts.size > 0
      ri = @path.rindex(/[^\/]\/?$/)
      ri = 0 if ri.nil?
      return Pointer.new(parent_parts, @path[0, ri])
    end

    # Returns the element name at which this pointer points to.
    #
    # ```
    # pointer = Json::Tools::Pointer.new("/foo/0/bar")
    # key = pointer.key # => bar
    # ```
    def key
      @path_parts[@path_parts.size - 1]
    end

    # Evaluates the pointer on the given JSON object.
    #
    # ```
    # json_obj = JSON.parse(<<-JSON
    #   {
    #     "foo": [
    #       {
    #         "bar": 12,
    #         "baz": 34
    #       },
    #       {
    #         "bar": 56,
    #         "baz": 78
    #       }
    #     ],
    #     "baz": "plaz"
    #   }
    #   JSON
    # )
    # pointer = Json::Tools::Pointer.new("/foo/1/bar")
    # value = pointer.eval(json_obj) # => 56
    # ```
    def eval(document : JSON::Any) : JSON::Any
      val = doEval(document)
      if val
        return val
      end
      raise PointerException.new(document, @path)
    end

    private def doEval(document : JSON::Any)
      @path_parts.reduce(document) { |doc, part|
        return nil unless doc
        return doc if part.blank?

        if doc.as_a?
          index = part.to_i?
          raise PointerException.new(doc, part) if index.nil?
          part = index
        end

        begin
          doc[part]
        rescue e : Exception
          raise PointerException.new(doc, part)
        end
      }
    end

    protected def self.parse(path : String)
      return [""] if path.size == 0 || path == "/"

      parts = [] of String
      path.sub(/^\//, "")
        .split(/(?<!\^)\//) { |part|
          parts << part.gsub(/\^[\/^]|~[01]/) { |m| ESCAPED_CHARS[m] }
        }

      parts.push("") if path[-1] == '/'
      return parts
    end
  end
end
