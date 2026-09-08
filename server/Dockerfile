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
        python3 \
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
# Auto-update de SteamCMD en el build (red del daemon). Evita el self-update a ciegas al arrancar.
RUN /home/steam/steamcmd/steamcmd.sh +quit \
    || /home/steam/steamcmd/steamcmd.sh +quit \
    || true

COPY --chmod=755 entrypoint.sh install-addons.sh install-8plus.sh install-workshop.sh expand-workshop.py /home/steam/
COPY gamedata-drop /home/steam/gamedata-drop
# Windows Git checkout is CRLF; Linux then looks for `bash\r`.
RUN sed -i 's/\r$//' /home/steam/entrypoint.sh /home/steam/install-addons.sh \
        /home/steam/install-8plus.sh /home/steam/install-workshop.sh /home/steam/expand-workshop.py
COPY cfg /home/steam/defaults/cfg

EXPOSE 27016/udp 27016/tcp

ENTRYPOINT ["/home/steam/entrypoint.sh"]
