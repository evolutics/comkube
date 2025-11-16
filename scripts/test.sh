#!/bin/bash

set -o errexit -o nounset -o pipefail

test_example() {
  if ! minikube status; then
    minikube start
  fi

  local -r namespace="${RANDOM}"
  kubectl create namespace "${namespace}"

  kubectl kustomize --enable-alpha-plugins example \
    | kubectl --namespace="${namespace}" apply --filename -

  kubectl --namespace="${namespace}" wait --for=condition=Available \
    deployment/greet

  local -r timeout_in_seconds=30
  minikube ssh -- curl --fail-with-body --max-time "${timeout_in_seconds}" \
    "$(kubectl --namespace="${namespace}" get service/greet \
      --template='{{.spec.clusterIP}}')":8080

  kubectl delete namespace "${namespace}"
}

main() {
  cd -- "$(dirname -- "$0")/.."

  travel-kit
  golangci-lint run --fix
  go test ./...

  docker build --build-arg "kompose_version=${KOMPOSE_VERSION}" \
    --tag ghcr.io/evolutics/comkube:dirty .

  test_example
}

main "$@"
