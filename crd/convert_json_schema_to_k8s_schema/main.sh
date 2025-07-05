#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

node dereference_json_schema.js | jq --from-file filter.jq
