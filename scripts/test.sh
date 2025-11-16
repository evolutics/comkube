#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")/.."

travel-kit
golangci-lint run --fix
go test ./...

docker build --build-arg "kompose_version=${KOMPOSE_VERSION}" \
  --tag ghcr.io/evolutics/comkube:dirty .
