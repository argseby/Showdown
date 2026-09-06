# syntax=docker/dockerfile:1

FROM golang:1.26.2-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# The release this image is built from, reported by `showdown -version`, the
# startup log and GET /api/config. CI passes the pushed tag.
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath \
    -ldflags="-s -w -X showdown/internal/buildinfo.version=${VERSION}" \
    -o /out/showdown ./cmd/server \
    && mkdir -p /out/data

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/showdown /showdown
# The data directory is created here, owned by nonroot, so that a fresh named
# volume mounted at /data is initialised writable for the non-root user.
COPY --from=build --chown=nonroot:nonroot /out/data /data
ENV LISTEN_ADDR=:8080 \
    DATA_DIR=/data
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/showdown"]
