#!/usr/bin/env bash
set -euo pipefail

for rc in /usr/local/libexec/opencode-container/entrypoint.d/*; do
    if [ -f "$rc" ]; then
        . "$rc"
    fi
done

# MISE_CONFIG_DIR keeps mise's config out of the volume-mounted home, so the
# version pinned at build time in /etc/mise cannot be overridden by accident.
#
# node@latest needs its own mise exec: mise only puts a tool on PATH for the
# command it runs, not for another tool's install phase, and @opencode/cli's
# postinstall shells out to `node` while opencode itself is being installed.
#
# BASH_ENV makes every non-interactive bash source mise activate, including
# the ones OpenCode's shell tool spawns.
exec env MISE_CONFIG_DIR=/etc/mise \
  mise exec node@latest -- \
  mise --cd /workspace exec opencode -- \
  env -u MISE_CONFIG_DIR \
  BASH_ENV=/home/agent/.bashrc.d/mise.sh \
  opencode serve --service --hostname 0.0.0.0 --port 49374
