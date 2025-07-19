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

crd/convert_json_schema_to_k8s_schema/test.sh

tilt ci --port 0

(
  cd chart
  helm lint --strict
)

kubectl kuttl test

tilt down
