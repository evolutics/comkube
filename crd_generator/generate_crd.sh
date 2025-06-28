#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

node dereference_json_schema.js <"${COMPOSE_JSON_SCHEMA}" \
  | jq '.spec.versions.[].schema.openAPIV3Schema.properties.spec = input' \
    crd_template.json - >../manifests/crd.json
