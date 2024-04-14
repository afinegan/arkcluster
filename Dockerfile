# syntax=docker/dockerfile:1
FROM phusion/baseimage:jammy-1.0.3
# https://github.com/phusion/baseimage-docker

LABEL org.opencontainers.image.authors="Andrew Finegan <andrew.finegan@gmail.com>" \
      org.opencontainers.image.title="ARK Cluster Image" \
      org.opencontainers.image.description="ARK Cluster Image" \
      org.opencontainers.image.url="https://github.com/afinegan/arkcluster" \
      org.opencontainers.image.source="https://github.com/afinegan/arkcluster"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN <<EOT bash # Install dependencies and clean up
    apt-get update
    apt-get upgrade -y -o Dpkg::Options::="--force-confold"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends bzip2 curl lib32gcc-s1 libc6-i386 lsof perl-modules tzdata libcompress-raw-zlib-perl
    apt-get clean
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOT

ARG ARKMANAGER_VERSION=1.6.62

# Add steam user and group
RUN groupadd steam && \
    useradd -r -g steam -d /home/steam -s /bin/bash steam && \
    mkdir -p /home/steam && \
    chown steam:steam /home/steam && \
    usermod -a -G docker_env steam

RUN <<EOT bash # Install ark-server-tools
    curl -sqL "https://github.com/arkmanager/ark-server-tools/archive/refs/tags/v${ARKMANAGER_VERSION}.tar.gz" | tar zxvf -
    pushd "./ark-server-tools-${ARKMANAGER_VERSION}/tools"
    ./install.sh steam --bindir=/usr/bin
    popd
    rm -r "ark-server-tools-${ARKMANAGER_VERSION}"
EOT

RUN mkdir -p /ark/log /ark/backup /ark/staging /ark/default /ark/steam /ark/.steam /cluster

# Fix permissions
RUN chown steam:steam -R /ark /cluster /home/steam

# Setup arkcluster
RUN mkdir -p /etc/service/arkcluster
COPY run.sh /etc/service/arkcluster/run
RUN chmod +x /etc/service/arkcluster/run
COPY arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager-user.cfg /home/steam/arkmanager-user.cfg
COPY /serversettings/config.Game.ini /home/steam/config.Game.ini
COPY /serversettings/config.GameUserSettings.ini /home/steam/config.GameUserSettings.ini

# Healthcheck
COPY crontab /home/steam/crontab
COPY healthcheck.sh /bin/healthcheck
RUN chmod +x /bin/healthcheck
HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=3 CMD [ /bin/healthcheck ]

# Fix permissions
RUN chown steam:steam -R /ark /cluster /home/steam

USER steam
RUN <<EOT bash # Install steamcmd
    ln -s /ark/steam /home/steam/Steam
    ln -s /ark/.steam /home/steam/.steam
    mkdir -p ~/steamcmd && cd ~/steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    ./steamcmd.sh +quit
EOT

# Expose environment variables
ENV CRON_AUTO_UPDATE="0 */3 * * *" \
    CRON_AUTO_BACKUP="0 */1 * * *" \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    TZ=UTC \
    MAX_BACKUP_SIZE=500 \
    SERVERMAP="TheIsland" \
    SESSION_NAME="ARK Docker" \
    MAX_PLAYERS=15 \
    RCON_ENABLE="True" \
    QUERY_PORT=15000 \
    GAME_PORT=15002 \
    RCON_PORT=15003 \
    SERVER_PVE="False" \
    SERVER_PASSWORD="" \
    ADMIN_PASSWORD="" \
    SPECTATOR_PASSWORD="" \
    MODS="" \
    CLUSTER_ID="keepmesecret" \
    KILL_PROCESS_TIMEOUT=300 \
    KILL_ALL_PROCESSES_TIMEOUT=300

USER root
VOLUME /ark /cluster
WORKDIR /ark
