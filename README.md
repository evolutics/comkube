# Comkube: Deploy Docker Compose Apps on Kubernetes

Keep your Compose files but deploy them on Kubernetes.

## Prerequisites

- Docker
- kubectl (includes kustomize)

## Usage

We assume:

- You already have your `compose.yaml` (or `docker-compose.yaml`) file.
- Your kubectl uses the desired kubeconfig context.

First, we need the following extra files in the same folder as your
`compose.yaml`:

1. File [`kustomization.yaml`](example/kustomization.yaml) is the entry point
   for the kustomize tool, which can generate and transform Kubernetes
   manifests:

   ```yaml
   generators:
     - my-k8s-compose-app.yaml
   ```

1. File [`my-k8s-compose-app.yaml`](example/my-k8s-compose-app.yaml) is the
   bridge to your `compose.yaml`; it tells kustomize to use the plugin Comkube
   (run in a container):

   ```yaml
   apiVersion: comkube.evolutics.info/v1alpha1
   kind: ComposeApp
   metadata:
     name: my-app
     annotations:
       config.kubernetes.io/function: |
         container:
           image: ghcr.io/evolutics/comkube:0.1.1
           mounts:
             - type: bind
               src: compose.yaml
               dst: /srv/compose.yaml
   ```

That's it. Now you are ready to deploy your Compose app to Kubernetes for real:

```bash
cd folder/with/above/files/
kubectl kustomize --enable-alpha-plugins . | kubectl apply --filename -
```

`kubectl kustomize --enable-alpha-plugins .` converts your Compose file into
Kubernetes manifests and prints the result (to stdout). Then
`kubectl apply --filename -` applies these manifests (given on stdin), that is,
it creates or updates the corresponding Kubernetes objects.

## Config reference

| Field                       | Type            | Meaning                                                                                      |
| --------------------------- | --------------- | -------------------------------------------------------------------------------------------- |
| `spec.composeFileInline`    | YAML            | Compose file contents to override default `(docker-)compose.yaml`.                           |
| `spec.composeFiles`         | String sequence | Compose file paths to override default `(docker-)compose.yaml`.                              |
| `spec.profiles`             | String sequence | Enabled [profiles](https://github.com/compose-spec/compose-spec/blob/main/spec.md#profiles). |
| `spec.withDebugAnnotations` | Boolean         | Whether to annotate Kubernetes manifests with optional metadata.                             |

## Related projects

If you need to convert your Compose files to Kubernetes manifest files once,
from then on maintaining those Kubernetes manifests, then use
[Kompose](https://kompose.io) directly. Comkube uses Kompose underneath.

## TODO

- Consider pruning using kubectl ApplySet.
- Distribute kubectl plugin with Krew.
- Document Podman support.
- Provide kubectl plugin.
