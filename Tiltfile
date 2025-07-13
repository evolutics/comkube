local_resource(
    "crd",
    cmd="crd/generate_crd/main.sh >helm_chart/crds/compose-app.json",
    deps="crd",
)

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

k8s_yaml(helm("helm_chart"))
k8s_resource("chart-comkube")
