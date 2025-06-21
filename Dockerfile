FROM scratch
COPY target/x86_64-unknown-linux-musl/debug/comkube /
ENTRYPOINT ["/comkube"]
# TODO: Consider building in image.
# TODO: Provide multi-arch image.
