package "cafe.util"

  HashMap: class HashMap

    @toQueryString: (object) ->
      s = []

      add = (key, value) ->
        # If value is a function, invoke it and return its value
        value = if typeof value is "function" then value() else value
        s[ s.length ] = encodeURIComponent(key) + "=" + encodeURIComponent(value)

      build = (prefix, obj, add) ->
        if obj instanceof Array and obj.length
          # Serialize array item.
          for v, i in obj
            if /\[\]$/.test(prefix)
              # Treat each array item as a scalar.
              add(prefix, v)

            else
              # If array item is non-scalar (array or object), encode its
              # numeric index to resolve deserialization ambiguity issues.
              # Note that rack (as of 1.0.0) can't currently deserialize
              # nested arrays properly, and attempting to do so may cause
              # a server error. Possible fixes are to modify rack's
              # deserialization algorithm or to provide an option or flag
              # to force array serialization to be shallow.
              build(prefix + "[" + (if typeof v is "object" or v instanceof Array then i else "" ) + "]", v, add)

        else if obj isnt null and typeof obj is "object"
          # Serialize object item.

          collection = build(prefix + "[" + k + "]", v, add) for k, v of obj

          add(prefix, "") if collection.length is 0

        else
          # Serialize scalar item.
          add(prefix, obj)

      # If an array was passed in, assume that it is an array of form elements.
      if object instanceof Array
        for item in object
          add(item.name, item.value) if item.name

      else if object instanceof Object
        for prefix, item of object
          build(prefix, item, add)

      # Return the resulting serialization
      return s.join("&").replace(/%20/g, "+")
