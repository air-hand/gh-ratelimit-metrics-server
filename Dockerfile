FROM homebrew/brew:latest as brew

FROM prom/prometheus:latest as prometheus

FROM mcr.microsoft.com/devcontainers/go:1.22-bookworm as builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    GO111MODULE=on

COPY --from=brew /home/linuxbrew /home/linuxbrew

COPY --from=prometheus /bin/promtool /usr/local/bin/promtool

WORKDIR /work

RUN chown -R vscode:vscode /work \
    && chown -R vscode:vscode /go

USER vscode

RUN go install github.com/bitnami/wait-for-port@v1.0.7 \
    ;

COPY --chown=vscode:vscode Makefile go.mod go.sum ./
COPY --chown=vscode:vscode ./app ./app

RUN make build

FROM gcr.io/distroless/base-debian12:latest as release

COPY --from=builder --chown=nonroot:nonroot /work/build/app /app

USER nonroot

ENTRYPOINT ["/app"]
