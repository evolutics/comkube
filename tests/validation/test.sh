#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

../../scripts/test_utility_cases.py kubectl apply --dry-run=server \
  --filename=- <test_cases.json
