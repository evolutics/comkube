#!/bin/bash

set -o errexit -o nounset -o pipefail

MY_GREETING='Hello' MY_NAME='world' kubectl kustomize --enable-alpha-plugins . \
  | prettier --parser yaml \
  | diff --label 'Actual' --unified - expected.yaml
