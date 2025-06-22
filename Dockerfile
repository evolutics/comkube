FROM scratch

# Update-worthy.
ADD --chmod=555 \
  https://github.com/kubernetes/kompose/releases/download/v1.36.0/kompose-linux-amd64 \
  /kompose

COPY target/x86_64-unknown-linux-musl/debug/comkube /
ENTRYPOINT ["/comkube"]

# TODO: Consider building in image.
# TODO: Provide multi-arch image.
# TODO: Validate integrity of Kompose executable using hash.
