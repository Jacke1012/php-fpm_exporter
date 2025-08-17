# ---- Builder ----
FROM golang:1.25-alpine AS build
RUN apk add --no-cache git ca-certificates && update-ca-certificates
WORKDIR /src

# Cache deps separately for faster rebuilds
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Build
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -v -o /out/php-fpm_exporter .

# ---- Final ----
FROM alpine:latest

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

#COPY php-fpm_exporter /

COPY --from=build /out/php-fpm_exporter /php-fpm_exporter

EXPOSE     9253
ENTRYPOINT [ "/php-fpm_exporter", "server" ]

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="php-fpm_exporter" \
      org.label-schema.description="A prometheus exporter for PHP-FPM." \
      org.label-schema.url="https://hipages.com.au/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/hipages/php-fpm_exporter" \
      org.label-schema.vendor="hipages" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run -it --rm -e PHP_FPM_SCRAPE_URI=\"tcp://127.0.0.1:9000/status\" hipages/php-fpm_exporter"
