#!/usr/bin/env bash
set -euo pipefail

for rc in /usr/local/libexec/opencode-container/entrypoint.d/*; do
    if [ -f "$rc" ]; then
        . "$rc"
    fi
done

# MISE_CONFIG_DIR keeps mise's config out of the volume-mounted home, so the
# version pinned at build time in /etc/mise cannot be overridden by accident.
exec env MISE_CONFIG_DIR=/etc/mise \
  mise --cd /workspace exec opencode -- \
  env -u MISE_CONFIG_DIR \
  opencode serve --service --hostname 0.0.0.0 --port 49374
