#!/bin/bash

set -o errexit -o nounset -o pipefail

kubectl kustomize --enable-alpha-plugins . | kubectl apply --filename=-

kubectl wait --for=condition=Available deployment/greet

minikube ssh -- curl --fail-with-body \
  "$(kubectl get service/greet --template='{{.spec.clusterIP}}')":8080
