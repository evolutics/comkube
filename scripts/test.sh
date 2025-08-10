#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")/.."

travel-kit

rustup component add rustfmt
cargo fmt --all -- --check

rustup component add clippy
cargo clippy --all-features --all-targets -- --deny warnings

cargo check
cargo test

crd/convert_json_schema_to_k8s_schema/test_idempotence.sh

tilt ci --port 0

scripts/test_utility_cases.py \
  crd/convert_json_schema_to_k8s_schema/test_suite.json \
  tests/validation.json

chart/dev/test.sh
kubectl kuttl test

tilt down
