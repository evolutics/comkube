# TODO: Provide multi-arch image.

# Update-worthy.
FROM docker.io/golang:1.25-alpine AS build

WORKDIR /usr/src/comkube
RUN grep '^nobody:' /etc/passwd >passwd
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -ldflags='-s' -o /usr/local/bin/comkube -v internal/app/main.go

FROM scratch

COPY --from=build /usr/src/comkube/passwd /etc/passwd

WORKDIR /usr/local/bin

ADD \
  --checksum=sha256:0861a3d612d8825a530ff566a0e8fda788a46eeaa390b613561a2b557b5e6b58 \
  --chmod=555 \
  https://github.com/kubernetes/kompose/releases/download/v1.37.0/kompose-linux-amd64 \
  kompose

COPY --from=build /usr/local/bin/comkube .
ENTRYPOINT ["comkube"]

WORKDIR /srv
