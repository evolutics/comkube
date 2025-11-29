#!/bin/bash

set -o errexit -o nounset -o pipefail

build_image() {
  local -r latest_git_tag="$(git describe --abbrev=0)"
  local -r latest_image_tag="${latest_git_tag#v}"

  local -r image="ghcr.io/evolutics/comkube:${latest_image_tag}"
  docker build --load --pull --tag "${image}" .

  echo "${image}"
}

test_kompose_version_in_image_is_consistent_with_native_env() {
  local -r image_version_line="$(docker run --entrypoint kompose --rm "$1" \
    version)"
  local -r native_version_line="$(kompose version)"

  local -r image_version="${image_version_line%% *}"
  local -r native_version="${native_version_line%% *}"

  if [[ "${image_version}" != "${native_version}" ]]; then
    echo "Kompose version in image is ${image_version}, \
which is inconsistent with native version ${native_version}." >&2
    return 1
  fi
}

test_examples() {
  if ! minikube status; then
    minikube start
  fi

  readarray -t example_folders < <(find examples -mindepth 1 -type d)
  local -r example_folders

  for example_folder in "${example_folders[@]}"; do
    (
      cd "${example_folder}"
      test_example "$1"
    )
  done
}

test_example() {
  if ! grep --fixed-strings --line-regexp "        image: $1" \
    my-k8s-compose-app.yaml; then
    echo "Example should refer to latest version of image: $1" >&2
    return 1
  fi

  local -r namespace="${RANDOM}"
  kubectl create namespace "${namespace}"
  kubectl config set-context --current --namespace="${namespace}"

  ./test.sh

  kubectl delete namespace "${namespace}"
}

main() {
  cd -- "$(dirname -- "$0")/.."

  travel-kit
  golangci-lint run --fix
  go test ./...

  local -r image="$(build_image)"
  test_kompose_version_in_image_is_consistent_with_native_env "${image}"
  test_examples "${image}"
}

main "$@"
