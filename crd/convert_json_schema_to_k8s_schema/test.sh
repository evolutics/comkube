#!/bin/bash

set -o errexit -o nounset -o pipefail

test_cases() {
  readarray test_cases \
    < <(jq --compact-output 'to_entries | .[]' <test_cases.json)
  local status=0

  for test_case in "${test_cases[@]}"; do
    summary="$(echo "${test_case}" | jq '.key')"
    input="$(echo "${test_case}" | jq '.value.input')"
    expected_output="$(echo "${test_case}" | jq '.value.expected_output')"

    actual_output="$(./main.sh <<<"${input}")"

    if ! diff --label "${summary}" --report-identical-files --unified \
      <(echo "${actual_output}" | jq) <(echo "${expected_output}"); then
      status=1
    fi
  done

  return "${status}"
}

test_idempotence() {
  local -r k8s_schema="$(./main.sh <"${COMPOSE_JSON_SCHEMA}")"
  diff --label 'Idempotence: one application' --label 'Two applications' \
    --unified <(echo "${k8s_schema}") <(echo "${k8s_schema}" | ./main.sh)
}

main() {
  cd -- "$(dirname -- "$0")"

  test_cases
  test_idempotence
}

main "$@"
