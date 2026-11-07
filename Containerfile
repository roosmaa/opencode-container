FROM quay.io/fedora/fedora:latest

# See for podman in podman specifics: https://github.com/podman-container-tools/image_build/tree/main/podman

RUN useradd -m -u 1000 -G wheel agent \
  && echo -e "agent:1:999\nagent:1001:64535" > /etc/subuid \
  && echo -e "agent:1:999\nagent:1001:64535" > /etc/subgid \
  && echo 'agent ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/agent \
  && chmod 0440 /etc/sudoers.d/agent

RUN dnf -y makecache \
  && dnf -y update \
  && dnf copr enable jdxcode/mise -y \
  && rpm --setcaps shadow-utils 2>/dev/null \
  && dnf install -y podman procps-ng mise --exclude container-selinux \
  && dnf clean all

COPY containers.conf /etc/containers/containers.conf
COPY libexec /usr/local/libexec/opencode-container

# Pin latest opencode version globally
RUN mkdir -p /etc/mise \
  && sudo --user=agent mise use -g --pin opencode@latest --dry-run 2>&1 \
     | sed -nE 's/^mise opencode@([^ ]+).*/\[tools\]\nopencode = "\1"/p' \
     | tee /etc/mise/config.toml

VOLUME /home/agent
# `podman build` makes use of /var/tmp, so it needs a separate volume
VOLUME /var/tmp

USER agent
EXPOSE 49374

CMD /usr/local/libexec/opencode-container/entrypoint.sh
