#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

jq --from-file ../convert_json_schema_to_k8s_schema/filter.jq \
  <"${COMPOSE_JSON_SCHEMA}" \
  | jq '.spec.versions.[].schema.openAPIV3Schema.properties.spec = input' \
    crd_template.json -
