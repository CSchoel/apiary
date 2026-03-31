# Proxmox is available as debian image, so we take the smallest debian-based image we can get.
FROM debian:13.4-slim
LABEL version="0.1.0"
LABEL description="Makes proxmox-auto-install-assistant available on non-debian systems."
# We need to download the Proxmox gpg key, so we install wget.
# We also need to authenticate the validity of the download server, so we need ca-certificates.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*;
# Get the Proxmomx keyring for the apt repository.
RUN wget -qO /usr/share/keyrings/proxmox-archive-keyring.gpg https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg
# Add the free version of the Proxmox apt repository.
# NOTE: The HEREDOC syntax needs docker-buildx-plugin or you will get an error 'COPY failed: no source files were specified'.
COPY <<EOF /etc/apt/sources.list.d/proxmox.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
# Install proxmox-auto-install-assistant from Proxmox repo.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends proxmox-auto-install-assistant && \
    rm -rf /var/lib/apt/lists/*
# Set proxmox-auto-install-assistant as entrypoint to the container.
ENTRYPOINT ["proxmox-auto-install-assistant"]
