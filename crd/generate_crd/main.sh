#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

../convert_json_schema_to_k8s_schema/main.sh <"${COMPOSE_JSON_SCHEMA}" \
  | jq '.spec.versions.[].schema.openAPIV3Schema.properties.spec = input' \
    crd_template.json -
