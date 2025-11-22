# Update-worthy.
FROM --platform="${BUILDPLATFORM}" docker.io/golang:1.25-alpine AS build

WORKDIR /usr/src/comkube
RUN grep '^nobody:' /etc/passwd >passwd
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETOS TARGETARCH
RUN GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
  go build -ldflags='-s' -o /usr/local/bin/comkube -v internal/app/main.go

FROM scratch AS kompose
ADD \
  --checksum=sha256:0861a3d612d8825a530ff566a0e8fda788a46eeaa390b613561a2b557b5e6b58 \
  --chmod=555 \
  https://github.com/kubernetes/kompose/releases/download/v1.37.0/kompose-linux-amd64 \
  /usr/local/bin/
ADD \
  --checksum=sha256:cd6fdf8f4560a936e574c11520993f2cc0afe4401b9cea01ce5d746f3cf04013 \
  --chmod=555 \
  https://github.com/kubernetes/kompose/releases/download/v1.37.0/kompose-linux-arm64 \
  /usr/local/bin/

FROM scratch
# See https://github.com/opencontainers/image-spec/blob/main/annotations.md.
LABEL org.opencontainers.image.authors='Benjamin Fischer'
LABEL org.opencontainers.image.url='https://github.com/evolutics/comkube'
LABEL org.opencontainers.image.documentation='https://github.com/evolutics/comkube'
LABEL org.opencontainers.image.source='https://github.com/evolutics/comkube'
LABEL org.opencontainers.image.version='0.1.0'
LABEL org.opencontainers.image.vendor='Benjamin Fischer'
LABEL org.opencontainers.image.licenses='MIT'
LABEL org.opencontainers.image.title='Comkube'
LABEL org.opencontainers.image.description='Deploy Docker Compose apps on Kubernetes'

COPY --from=build /usr/src/comkube/passwd /etc/passwd

WORKDIR /usr/local/bin

ARG TARGETARCH
COPY --from=kompose "/usr/local/bin/kompose-linux-${TARGETARCH}" kompose

COPY --from=build /usr/local/bin/comkube .
ENTRYPOINT ["comkube"]

WORKDIR /srv
