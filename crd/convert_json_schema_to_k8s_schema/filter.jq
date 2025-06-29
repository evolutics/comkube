del(.definitions)
| walk(
    if type == "object"
      and has("patternProperties") and (.patternProperties | type) == "object"
      and (.patternProperties | length) == 1
      and has("additionalProperties") and (.additionalProperties == false) then
      .additionalProperties = .patternProperties.[] | del(.patternProperties)
    else
      .
    end
  )
