# syntax=docker/dockerfile:1

# Base image
FROM phusion/baseimage:jammy-1.0.3

# Metadata
LABEL org.opencontainers.image.authors="Andrew Finegan <andrew.finegan@gmail.com>" \
      org.opencontainers.image.title="ARK Cluster Image" \
      org.opencontainers.image.description="This Docker image provides an ARK server cluster environment." \
      org.opencontainers.image.url="https://github.com/afinegan/arkcluster" \
      org.opencontainers.image.source="https://github.com/afinegan/arkcluster"

# Set default command
CMD ["/sbin/my_init"]

# Install dependencies, clean up in one layer to reduce image size
RUN apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bzip2 curl lib32gcc-s1 libc6-i386 lsof perl-modules tzdata libcompress-raw-zlib-perl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define version as a build argument to make it configurable at build time
ARG ARKMANAGER_VERSION=1.6.62

# Add steam user and group, add to `docker_env` group, use a more readable format for RUN instructions
RUN groupadd steam && \
    useradd -r -g steam -d /home/steam -s /bin/bash steam && \
    usermod -a -G docker_env steam && \
    mkdir -p /home/steam && \
    chown steam:steam /home/steam

# Install ARK Manager
RUN curl -sL "https://github.com/arkmanager/ark-server-tools/archive/refs/tags/v${ARKMANAGER_VERSION}.tar.gz" | tar zxvf - && \
    cd "ark-server-tools-${ARKMANAGER_VERSION}/tools" && \
    ./install.sh steam --bindir=/usr/bin && \
    cd ../../ && \
    rm -rf "ark-server-tools-${ARKMANAGER_VERSION}"

# Prepare directories and set permissions
RUN mkdir -p /ark/log /ark/backup /ark/staging /ark/default /ark/steam /ark/.steam /cluster && \
    chown -R steam:steam /ark /cluster /home/steam

# Copy configuration files and scripts
COPY run.sh /etc/service/arkcluster/run
COPY arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager-user.cfg /home/steam/arkmanager-user.cfg
COPY /serversettings/config.Game.ini /home/steam/config.Game.ini
COPY /serversettings/config.GameUserSettings.ini /home/steam/config.GameUserSettings.ini
COPY crontab /home/steam/crontab
COPY healthcheck.sh /bin/healthcheck
RUN chmod +x /etc/service/arkcluster/run /bin/healthcheck

# Configure health check
HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=3 CMD [ "/bin/healthcheck" ]

# Switch to user 'steam'
USER steam

# Install steamcmd
RUN mkdir -p ~/steamcmd && \
    cd ~/steamcmd && \
    curl -sL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    ./steamcmd.sh +quit

# Set environment variables
ENV CRON_AUTO_UPDATE="0 */3 * * *" \
    CRON_AUTO_BACKUP="*/5 * * * *" \
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

# Reset to root for volume and workdir commands
USER root

# Define volumes and working directory
VOLUME ["/ark", "/cluster"]
WORKDIR /ark