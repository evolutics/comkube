FROM scratch

ENV PATH=/
# Update-worthy.
ADD --chmod=555 \
  https://github.com/kubernetes/kompose/releases/download/v1.36.0/kompose-linux-amd64 \
  /kompose

COPY target/x86_64-unknown-linux-musl/debug/comkube /
ENTRYPOINT ["/comkube"]

# TODO: Check if `USER 1000` is convenient for `securityContext.runAsNonRoot`.
# TODO: Consider building in image.
# TODO: Provide multi-arch image.
# TODO: Validate integrity of Kompose executable using hash.
