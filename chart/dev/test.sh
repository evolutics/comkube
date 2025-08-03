#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

helm lint --strict ..

helm install my-release .. --dry-run \
  | sed --quiet '/^NOTES:$/,$p' \
  | diff --label 'Actual notes' --unified - expected_notes.md
