# OpenCode on Render — headless agent server
#
# Runs the same OpenCode binary you use in Termux, but as a server:
#   opencode serve  ->  web UI + HTTP API on Render's PORT
#
# Data (sessions, config, credentials, cloned repo) lives in /data,
# which must be a Render Persistent Disk.

FROM node:22-bookworm-slim

ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive

# Tooling your agent will actually need when it runs commands/builds.
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git jq openssh-client ripgrep \
      unzip xz-utils build-essential python3 python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Standalone OpenCode CLI (single self-contained binary, same as the Termux one).
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) arch="x64" ;; \
      arm64) arch="arm64" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 5 --retry-delay 3 \
      "https://opencode.ai/update/api/latest/cli/opencode/opencode-linux-${arch}.tar.gz" \
      | tar -xz -C /usr/local/bin; \
    chmod +x /usr/local/bin/opencode; \
    opencode --version

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Everything the agent persists goes under $HOME, so point HOME at the disk.
ENV HOME=/data
WORKDIR /data

EXPOSE 4096
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
