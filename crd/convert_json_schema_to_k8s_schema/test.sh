#!/bin/bash

set -o errexit -o nounset -o pipefail

test_idempotence() {
  local -r k8s_schema="$(convert_schema <"${COMPOSE_JSON_SCHEMA}")"
  diff --label 'Idempotence: one application' --label 'Two applications' \
    --unified <(echo "${k8s_schema}") <(echo "${k8s_schema}" | convert_schema)
}

convert_schema() {
  jq --from-file filter.jq
}

main() {
  cd -- "$(dirname -- "$0")"

  ../../scripts/test_utility_cases.py jq --from-file filter.jq <test_cases.json
  test_idempotence
}

main "$@"
