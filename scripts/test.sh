#!/bin/bash

set -o errexit -o nounset -o pipefail

test_image_labels() {
  local -r title="$(docker image inspect --format \
    '{{index .Config.Labels "org.opencontainers.image.title"}}' \
    ghcr.io/evolutics/comkube:dirty)"
  local -r description="$(docker image inspect --format \
    '{{index .Config.Labels "org.opencontainers.image.description"}}' \
    ghcr.io/evolutics/comkube:dirty)"

  if ! grep --ignore-case "^# ${title}: ${description}$" README.md; then
    echo 'Image labels are inconsistent with readme title.' >&2
    return 1
  fi
}

test_kompose_version_in_image_is_consistent_with_native_env() {
  local -r image_version_line="$(docker run --entrypoint kompose --rm \
    ghcr.io/evolutics/comkube:dirty version)"
  local -r native_version_line="$(kompose version)"

  local -r image_version="${image_version_line%% *}"
  local -r native_version="${native_version_line%% *}"

  if [[ "${image_version}" != "${native_version}" ]]; then
    echo "Kompose version in image is ${image_version}, \
which is inconsistent with native version ${native_version}." >&2
    return 1
  fi
}

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

  local -r timeout_in_seconds=60
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

  docker build --load --tag ghcr.io/evolutics/comkube:dirty .

  test_image_labels
  test_kompose_version_in_image_is_consistent_with_native_env
  test_example
}

main "$@"
