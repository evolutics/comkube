#!/bin/bash

set -o errexit -o nounset -o pipefail

main() {
  cd -- "$(dirname -- "$0")"

  readarray test_cases < <(jq --compact-output '.[]' <test_cases.json)
  local status=0

  for test_case in "${test_cases[@]}"; do
    summary="$(echo "${test_case}" | jq '.summary')"
    input="$(echo "${test_case}" | jq '.input')"
    expected_output="$(echo "${test_case}" | jq '.expected_output')"

    actual_output="$(./main.sh <<<"${input}")"

    if ! diff --label "${summary}" --report-identical-files --unified \
      <(echo "${actual_output}" | jq) <(echo "${expected_output}"); then
      status=1
    fi
  done

  return "${status}"
}

main "$@"
