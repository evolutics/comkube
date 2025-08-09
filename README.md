# Comkube: Deploy Docker Compose Apps on Kubernetes

## Development

```bash
minikube start
tilt up
```

## TODO

- Clean up objects, e.g., when 1 of 2 services is dropped from Compose config.
- Handle errors, e.g., from `unwrap`.
- Handle updates to immutable fields where patch fails.
- Provide Docker plugin that essentially does
  `docker compose config --format json "$@" | kubectl apply --filename -`.
