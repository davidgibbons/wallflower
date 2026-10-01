FROM debian:trixie-slim
LABEL org.opencontainers.image.source=https://github.com/davidgibbons/wallflower
RUN apt-get update && apt-get install -y --no-install-recommends \
        xserver-xorg-core xserver-xorg-input-libinput xinit x11-xserver-utils xinput scrot \
        libgl1-mesa-dri chromium chromium-sandbox fonts-dejavu-core \
        curl jq ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 -s /bin/bash kiosk
COPY rootfs/ /
ENTRYPOINT ["/usr/local/bin/kiosk-container"]
