FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        libcurl4:i386 \
        libsdl2-2.0-0:i386 \
        locales \
        tar \
        gzip \
    && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
    && locale-gen \
    && useradd --create-home --shell /bin/bash --uid 1000 steam \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    GAME_DIR=/home/steam/l4d2

USER steam
WORKDIR /home/steam

RUN mkdir -p /home/steam/steamcmd /home/steam/l4d2 \
    && curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
        | tar -xz -C /home/steam/steamcmd

COPY --chmod=755 entrypoint.sh install-addons.sh /home/steam/
COPY cfg /home/steam/defaults/cfg

EXPOSE 27015/udp 27015/tcp

ENTRYPOINT ["/home/steam/entrypoint.sh"]
