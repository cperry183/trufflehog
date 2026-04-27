FROM --platform=${BUILDPLATFORM} golang:bullseye AS builder

WORKDIR /build

# Cache dependencies before copying source to maximize layer cache reuse
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

ARG TARGETOS TARGETARCH
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o trufflehog .

# ---- runtime ----
FROM alpine:3.22

RUN apk add --no-cache \
        bash \
        git \
        openssh-client \
        ca-certificates \
        rpm2cpio \
        binutils \
        cpio \
    && update-ca-certificates

COPY --from=builder /build/trufflehog /usr/bin/trufflehog
COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh

ENTRYPOINT ["/etc/entrypoint.sh"]
