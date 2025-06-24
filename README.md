# Comkube: Deploy Docker Compose apps on Kubernetes

## Development

```
minikube start
tilt up

kubectl apply --filename=manifests/object.yaml
kubectl describe service/greet
minikube ssh -- \
  curl "$(kubectl get service/greet --template='{{.spec.clusterIP}}')":8080
```

## TODO

- Clean up objects, e.g., when 1 of 2 services is dropped from Compose config.
- Handle errors, e.g., from `unwrap`.
- Provide Docker plugin that essentially does
  `docker compose config --format json "$@" | kubectl apply --filename -`.
