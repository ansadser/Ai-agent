#!/usr/bin/env bash
# OpenCode on Render — entrypoint
set -euo pipefail

log() { printf '%s [entrypoint] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

# ---------------------------------------------------------------- home / XDG
export HOME="${HOME:-/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# ---------------------------------------------------------------- secrets
if [ -z "${OPENCODE_PASSWORD:-}" ]; then
  log "ERROR: OPENCODE_PASSWORD is not set."
  log "Add it in Render -> Environment (long random string). It is the web/TUI login."
  exit 1
fi

PORT="${PORT:-4096}"
WORKSPACE="${WORKSPACE:-$HOME/workspace}"
REPO_URL="${REPO_URL:-}"

# ---------------------------------------------------------------- git setup
git config --global user.name  "${GIT_AUTHOR_NAME:-OpenCode Agent}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-agent@users.noreply.github.com}"
git config --global init.defaultBranch main
git config --global --add safe.directory '*'

# ---------------------------------------------------------------- workspace
if [ -n "$REPO_URL" ]; then
  auth_url="$REPO_URL"
  if [ -n "${GITHUB_TOKEN:-}" ] && [[ "$auth_url" == https://* ]]; then
    auth_url="https://x-access-token:${GITHUB_TOKEN}@${REPO_URL#https://}"
  fi

  if [ -d "$WORKSPACE/.git" ]; then
    log "refreshing existing workspace $WORKSPACE"
    git -C "$WORKSPACE" remote set-url origin "$auth_url" || true
    git -C "$WORKSPACE" fetch --all --prune || log "fetch failed, continuing with local copy"
  elif [ ! -e "$WORKSPACE" ] || [ -z "$(ls -A "$WORKSPACE" 2>/dev/null || true)" ]; then
    log "cloning $REPO_URL into $WORKSPACE"
    mkdir -p "$(dirname "$WORKSPACE")"
    git clone "$auth_url" "$WORKSPACE"
  else
    log "workspace $WORKSPACE already has files, skipping clone"
  fi
else
  log "REPO_URL not set — starting with empty workspace at $WORKSPACE"
  mkdir -p "$WORKSPACE"
fi

cd "$WORKSPACE"

# ---------------------------------------------------------------- mode
# One-shot / cron mode: set RUN_PROMPT instead of serving a long-lived server.
if [ -n "${RUN_PROMPT:-}" ]; then
  log "one-shot agent run in $WORKSPACE"
  exec opencode run --auto --print-logs "$RUN_PROMPT"
fi

log "starting OpenCode server on 0.0.0.0:$PORT (workspace: $WORKSPACE)"
exec opencode serve --hostname 0.0.0.0 --port "$PORT" --print-logs
