# Update-worthy.
FROM --platform="${BUILDPLATFORM}" docker.io/golang:1.25-alpine AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /usr/src/comkube
RUN grep '^nobody:' /etc/passwd >passwd
COPY go.mod go.sum ./
RUN go mod download
COPY . .
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
ARG TARGETOS
ARG TARGETARCH
COPY --from=build /usr/src/comkube/passwd /etc/passwd
WORKDIR /usr/local/bin
COPY --from=kompose "/usr/local/bin/kompose-${TARGETOS}-${TARGETARCH}" kompose
COPY --from=build /usr/local/bin/comkube .
ENTRYPOINT ["comkube"]
WORKDIR /srv
