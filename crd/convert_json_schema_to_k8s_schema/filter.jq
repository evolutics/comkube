del(."$id")
  | del(.definitions)
  | walk(
    if type == "object" and .uniqueItems? == true then
      del(.uniqueItems)
    else
      .
    end
  )
  | walk(
    if type == "object" and (.deprecated? | type) == "boolean" then
      del(.deprecated)
    else
      .
    end
  )
  | walk(
    if type == "object" and (.properties? | type) == "object"
        and (has("patternProperties") | not)
        and .additionalProperties? == false then
      del(.additionalProperties)
    else
      .
    end
  )
  | walk(
    if type == "object" and (.patternProperties? | type) == "object"
        and (.patternProperties | length) == 1
        and (.additionalProperties? | . == null or . == false) then
      .additionalProperties = .patternProperties.[] | del(.patternProperties)
    else
      .
    end
  )
  | walk(
    if type == "object" and (.properties? | type) == "object"
        and .additionalProperties? == {} then
      ."x-kubernetes-preserve-unknown-fields" = true
        | del(.additionalProperties)
    else
      .
    end
  )
  | walk(
    if type == "object" and (.oneOf? | type) == "array"
        and any(.oneOf[]; .type? == "null") then
      .oneOf |= map(. + { "nullable": true })
        | del(.oneOf[] | select(.type? == "null"))
    else
      .
    end
  )
