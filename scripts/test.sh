#!/bin/bash

set -o errexit -o nounset -o pipefail

cd -- "$(dirname -- "$0")/.."

travel-kit
golangci-lint run --fix
go test ./...

go install
mv "${GOBIN}/comkube" "${GOBIN}/kubectl-comkube"
kubectl kuttl test
