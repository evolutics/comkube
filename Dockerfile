FROM scratch

ENV PATH=/

ARG kompose_version
ADD \
  --checksum=sha256:459d86a14a2172d8384007ff296f74f3c625dde15b6c8dc971f4985891aef3a7 \
  --chmod=555 \
  "https://github.com/kubernetes/kompose/releases/download/v${kompose_version}/kompose-linux-amd64" \
  /kompose

COPY target/x86_64-unknown-linux-musl/debug/comkube /
ENTRYPOINT ["/comkube"]

# TODO: Consider building in image.
# TODO: Provide multi-arch image.
