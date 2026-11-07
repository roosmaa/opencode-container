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

COPY bashrc.d/ /home/agent/.bashrc.d/
COPY containers.conf /home/agent/.config/containers/containers.conf
RUN mkdir -p /home/agent/.local/share/containers \
  && mkdir -p /home/agent/{.config,.cache} /home/agent/.local/{state,share} \
  && mkdir -p /opt/mise/{config,cache,state,share} \
  && mkdir -p /opt/opencode/{config,share} \
  && ln -s /opt/mise/config /home/agent/.config/mise \
  && ln -s /opt/mise/cache /home/agent/.cache/mise \
  && ln -s /opt/mise/state /home/agent/.local/state/mise \
  && ln -s /opt/mise/share /home/agent/.local/share/mise \
  && ln -s /opt/opencode/config /home/agent/.config/opencode \
  && ln -s /opt/opencode/share /home/agent/.local/share/opencode \
  && chown agent:agent -R /home/agent /opt

# Pin latest opencode version globally
RUN mkdir -p /etc/mise \
  && sudo --user=agent mise use -g --pin opencode@latest --dry-run 2>&1 \
     | sed -nE 's/^mise opencode@([^ ]+).*/\[tools\]\nopencode = "\1"/p' \
     | tee /etc/mise/config.toml

# Note VOLUME options must always happen after the chown call above
# RUN commands can not modify existing volumes
VOLUME /home/agent/.local/share/containers
VOLUME /opt

USER agent
EXPOSE 49374

# Force the mise exec to use only /etc/mise. This protects us
# from nasty surprises where ~/.config/mise would override
# the detected [above] opencode version.
CMD [ "env", "MISE_CONFIG_DIR=/etc/mise", \
      "mise", "--cd", "/workspace", "exec", "opencode", "--", \
      "env", "-u", "MISE_CONFIG_DIR", \
      "opencode", "serve", \
      "--service", \
      "--hostname", "0.0.0.0", \
      "--port", "49374" ]
