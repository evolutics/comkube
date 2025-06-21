local_resource(
    "executable",
    cmd="cargo build --target=x86_64-unknown-linux-musl",
    deps=["Cargo.lock", "Cargo.toml", "src"],
)
docker_build("ghcr.io/evolutics/comkube", ".")
k8s_yaml("manifests/controller.yaml")
k8s_yaml("manifests/crd.yaml")
k8s_resource("comkube")
