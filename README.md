# Comkube: Deploy Docker Compose apps on Kubernetes

## Development

```bash
minikube start
tilt up
```

## TODO

- Clean up objects, e.g., when 1 of 2 services is dropped from Compose config.
- Handle errors, e.g., from `unwrap`.
- Provide Docker plugin that essentially does
  `docker compose config --format json "$@" | kubectl apply --filename -`.
- Provide simple installation for Kubernetes admins, e.g., via Helm chart.
