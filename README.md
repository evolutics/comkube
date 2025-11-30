# Comkube: Deploy Docker Compose Apps on Kubernetes

In a hurry? Jump to [quick start](#quick-start)!

## Motivation

Keep your Compose files but deploy them on Kubernetes.

The conversion happens on the fly with [Kompose](https://kompose.io), providing
you with its flexibility to fine-tune as needed.

## Prerequisites

Comkube is distributed as a container image, so the only requirements are these:

- Docker
- kubectl (includes kustomize)

## Usage

### Quick start

We assume:

- You already have your `compose.yaml` (or `docker-compose.yaml`) file.
- Your kubectl uses the desired kubeconfig context.

First, we need the following extra files in the same folder as your
`compose.yaml`:

1. File [`kustomization.yaml`](examples/basic/kustomization.yaml) is the entry
   point for the kustomize tool, which can generate and transform Kubernetes
   manifests:

   ```yaml
   generators:
     - my-k8s-compose-app.yaml
   ```

1. File [`my-k8s-compose-app.yaml`](examples/basic/my-k8s-compose-app.yaml) is
   the bridge to your `compose.yaml`; it tells kustomize to use the plugin
   Comkube (run in a container):

   ```yaml
   apiVersion: comkube.evolutics.info/v1alpha1
   kind: ComposeApp
   metadata:
     name: my-app
     annotations:
       config.kubernetes.io/function: |
         container:
           image: "ghcr.io/evolutics/comkube:0.2.0"
           mounts:
             - type: bind
               src: compose.yaml
               dst: /srv/compose.yaml
   ```

That's it. Now you are ready to deploy your Compose app to Kubernetes for real:

```bash
cd folder/with/above/files/
kubectl kustomize --enable-alpha-plugins . | kubectl apply --filename=-
```

`kubectl kustomize --enable-alpha-plugins .` converts your Compose file into
Kubernetes manifests and prints the result (to stdout). Then
`kubectl apply --filename=-` applies these manifests (given on stdin), that is,
it creates or updates the corresponding Kubernetes objects.

### Container environment config

For security reasons,
[kustomize recommends](https://kubectl.docs.kubernetes.io/guides/extending_kustomize/)
running plugins in a container; we do the same with Comkube.

This implies that files and environment variables your Compose config depends on
must be provided to the container:

- **Files** like `compose.yaml` and `.env` files, if any, must be mounted
  – either individually or by mounting whole folders.

  Comkube's working folder is `/srv/`. Note that mounts are read-only by
  default.

- **Environment variables** that kustomize should pass from your host
  environment to the container must be named.

The following demonstrates this (see
[full example](examples/container_environment_config)):

```yaml
apiVersion: comkube.evolutics.info/v1alpha1
kind: ComposeApp
metadata:
  name: my-app
  annotations:
    config.kubernetes.io/function: |
      container:
        image: "ghcr.io/evolutics/comkube:0.2.0"
        mounts:
          - type: bind
            src: my_config/
            dst: /srv/
        envs:
           - MY_GREETING
           - MY_NAME
```

## Config reference

| Field                       | Type            | Meaning                                                                                              |
| --------------------------- | --------------- | ---------------------------------------------------------------------------------------------------- |
| `spec.composeFileInline`    | YAML            | Compose file contents to override default `(docker-)compose.yaml`.                                   |
| `spec.composeFiles`         | String sequence | Compose file paths to override default `(docker-)compose.yaml`.                                      |
| `spec.profiles`             | String sequence | Enabled Compose [profiles](https://github.com/compose-spec/compose-spec/blob/main/spec.md#profiles). |
| `spec.withDebugAnnotations` | Boolean         | Whether to annotate Kubernetes manifests with optional metadata.                                     |

## Related projects

If you need to convert your Compose files to Kubernetes manifest files once,
from then on maintaining those Kubernetes manifests, then use
[Kompose](https://kompose.io) directly.

## TODO

- Consider pruning using kubectl ApplySet.
- Distribute kubectl plugin with Krew.
- Document Podman support.
- Provide kubectl plugin.
