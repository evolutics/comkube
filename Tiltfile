local_resource("crd", cmd="crd_generator/generate_crd.sh", deps="crd_generator")

local_resource(
    "executable",
    cmd="cargo build --target=x86_64-unknown-linux-musl",
    deps=["Cargo.lock", "Cargo.toml", "src"],
)

docker_build(
    "ghcr.io/evolutics/comkube",
    ".",
    build_args={"kompose_version": os.getenv("KOMPOSE_VERSION")},
)

k8s_yaml("manifests/controller.yaml")
k8s_yaml("manifests/crd.yaml")
k8s_resource("comkube")
