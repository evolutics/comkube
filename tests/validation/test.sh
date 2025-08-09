#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")"

! kubectl apply --dry-run=server --filename invalid-spec.yaml
