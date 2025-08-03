NOTES:
Thanks for using Comkube.

Try deploying a Compose test app with

```
kubectl apply --filename - <<'EOF'
apiVersion: evolutics.info/v1
kind: ComposeApplication
metadata:
  name: foo
spec:
  services:
    greet:
      image: "docker.io/hashicorp/http-echo:1.0"
      command: ["-listen=:8282", "-text=Hi from Comkube"]
      ports:
        - "127.0.0.1:8080:8282"
EOF
```

This should create a Kubernetes service called `greet`, backed by a deployment
of the same name (see `kubectl get all`).

For debugging, show the controller logs by running

```
kubectl logs deployment/my-release-comkube
```

When done testing, delete the Compose test app including its owned objects with

```
kubectl delete composeapp foo
```

See the documentation at https://github.com/evolutics/comkube for more.
