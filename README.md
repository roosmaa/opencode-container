# opencode-container

A Fedora-based container that runs `opencode serve` as a long-lived service,
meant to be run as a user service with a persistent home volume.

## Run

```bash
podman volume create opencode-home

podman run -d --name opencode \
  --userns=keep-id:uid=1000,gid=1000 \
  --device /dev/fuse \
  --security-opt label=disable \
  -v opencode-home:/home/agent \
  -v "$HOME/Agent:/workspace" \
  -p 127.0.0.1:49374:49374 \
  ghcr.io/roosmaa/opencode-container
```

`/workspace` is where opencode starts, so mount the folder your projects live
in. The service listens on `49374` inside the container; the example publishes
it on localhost only.

The first start of a new home volume installs opencode with mise (~450 MB,
roughly 15 s). Later starts are instant. Everything runs as the unprivileged
`agent` user (uid 1000), which has passwordless sudo. If you keep SELinux
enabled, drop `--security-opt label=disable` and add `:z` to the volume flags
instead.

## Layout

| Path | |
| --- | --- |
| `/home/agent` | volume, persistent home — mise data and opencode state live here |
| `/var/tmp` | volume, storage for nested podman builds |
| `/workspace` | not in the image, mount your projects here |
| `/etc/mise/config.toml` | opencode version, resolved and pinned at build time |
| `/usr/local/libexec/opencode-container/` | entrypoint and hooks, deliberately not on `$PATH` |

## Entrypoint

`entrypoint.sh` sources every file in `libexec/entrypoint.d/` in name order,
then execs the server. A failing hook aborts the container. The bundled ones:

- `20-skel.sh` — restores `~/.bashrc` and friends from `/etc/skel`, so
  customize your shell through `~/.bashrc.d/*.sh`, which survives
- `30-bashrc.sh` — writes `~/.bashrc.d/mise.sh`, which puts mise on `$PATH`
- `90-chown.sh` — normalises ownership of the home directory

## Nested podman

The image ships podman so the agent can run containers of its own, with a
`/etc/containers/containers.conf` that runs inner containers in the outer
namespaces (`netns`/`userns`/`ipcns`/`utsns`/`cgroupns` host, cgroups disabled,
`crun`), which is why `--device /dev/fuse` and the `/var/tmp` volume are
required.

Approach and much of the reasoning come from [Podman inside a
container](https://www.redhat.com/en/blog/podman-inside-container) and
[podman-container-tools/image_build](https://github.com/podman-container-tools/image_build/tree/main/podman).

## Build

```bash
podman build -t ghcr.io/roosmaa/opencode-container .
```

GitHub Actions rebuilds and publishes `latest` on push to `main` and once a
day, which refreshes the Fedora base and re-resolves the pinned opencode
version.
