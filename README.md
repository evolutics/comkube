# Comkube: Deploy Docker Compose Apps on Kubernetes

In a hurry? Jump to [quick start](#quick-start)!

## Motivation

Keep your Compose files but deploy them on Kubernetes.

The conversion happens on the fly with [Kompose](https://kompose.io), providing
you with its flexibility to fine-tune as needed.

## Setup

### Prerequisites

kubectl

### Installation

```bash
go install github.com/evolutics/comkube@latest
```

TODO: Pre-built executables are coming soon.

## Usage

### Quick start

```bash
kubectl comkube up
```

## Related projects

If you need to convert your Compose files to Kubernetes manifest files once,
from then on maintaining those Kubernetes manifests, then use
[Kompose](https://kompose.io) directly.

## TODO

- Consider pruning using kubectl ApplySet.
- Consider using https://github.com/kubernetes/cli-runtime.
- Distribute kubectl plugin with Krew.
- Follow kubectl plugin contract.
