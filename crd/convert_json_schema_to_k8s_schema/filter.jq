del(."$id")
  | del(.definitions)
  | walk(
    if type == "object" and has("uniqueItems") and .uniqueItems == true then
      del(.uniqueItems)
    else
      .
    end
  )
  | walk(
    if type == "object"
        and has("deprecated") and (.deprecated | type) == "boolean" then
      del(.deprecated)
    else
      .
    end
  )
  | walk(
    if type == "object"
        and has("properties") and (.properties | type) == "object"
        and (has("patternProperties") | not)
        and has("additionalProperties")
        and (.additionalProperties == false) then
      del(.additionalProperties)
    else
      .
    end
  )
  | walk(
    if type == "object"
        and has("patternProperties") and (.patternProperties | type) == "object"
        and (.patternProperties | length) == 1
        and has("additionalProperties")
        and (.additionalProperties == false) then
      .additionalProperties = .patternProperties.[] | del(.patternProperties)
    else
      .
    end
  )
  | walk(
    if type == "object"
        and has("properties") and (.properties | type) == "object"
        and has("additionalProperties") and (.additionalProperties == {}) then
      ."x-kubernetes-preserve-unknown-fields" = true
        | del(.additionalProperties)
    else
      .
    end
  )
