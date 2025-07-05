def drop_restricted_fields:
  del(."$id")
    | del(."$schema")
    | del(.definitions)
    | walk(
      if type == "object" and (.deprecated | type) == "boolean" then
        del(.deprecated)
      else
        .
      end
    )
    | walk(
      if type == "object" and .uniqueItems == true then
        del(.uniqueItems)
      else
        .
      end
    )
    | walk(
      if type == "object" and .additionalProperties == false then
        del(.additionalProperties)
      else
        .
      end
    );

def rewrite_type_arrays:
  walk(
    if type == "object" and (.type | type) == "array"
        and any(.type[]; . == "null") then
      .nullable = true | .type -= ["null"]
    else
      .
    end
  )
    | walk(
      if type == "object" and (.type | type) == "array"
          and (.type | unique | length) == 1 then
        .type |= .[0]
      else
        .
      end
    );

def overapproximate_int_or_string:
  walk(
    if type == "object" and (.type | type) == "array"
        and (.type | unique) == ["integer", "string"] then
      ."x-kubernetes-int-or-string" = true | del(.type)
    else
      .
    end
  )
    | walk(
      if type == "object" and (.oneOf | type) == "array"
          and (.oneOf | map(.type) | unique) == ["integer", "string"] then
        .nullable = any(.oneOf[]; .nullable == true)
          | ."x-kubernetes-int-or-string" = true | del(.oneOf)
      else
        .
      end
    );

def overapproximate_singleton_pattern_properties:
  walk(
    if type == "object" and (.patternProperties | type) == "object"
        and (.patternProperties | length) == 1
        and (.additionalProperties | . == null or . == false) then
      .additionalProperties = .patternProperties.[] | del(.patternProperties)
    else
      .
    end
  );

def unsupported_schema:
  if type == "object" then
    if . == {} or (.type | type) == "array" then
      .
    elif (.oneOf | type) == "array" then
      .oneOf
    else
      null
    end
  else
    null
  end;

def overapproximate_unsupported_schemas:
  walk(
    if type == "object" and (.additionalProperties | unsupported_schema) then
      ."x-kubernetes-preserve-unknown-fields" = true
        | del(.additionalProperties)
    else
      .
    end
  )
    | walk(
      if type == "object" and (.properties | type) == "object"
          and any(.properties[]; unsupported_schema) then
        ."x-kubernetes-preserve-unknown-fields" = true
          | del(.properties[] | select(unsupported_schema))
      else
        .
      end
    )
    | walk(
      if type == "object" and (.properties | type) == "object"
          and any(.properties[]; .items | unsupported_schema) then
        ."x-kubernetes-preserve-unknown-fields" = true
          | del(.properties[] | select(.items | unsupported_schema))
      else
        .
      end
    );

drop_restricted_fields
  | rewrite_type_arrays
  | overapproximate_int_or_string
  | overapproximate_singleton_pattern_properties
  | overapproximate_unsupported_schemas
