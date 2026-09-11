FROM ubuntu:24.04
LABEL maintainer="NightDragon"
LABEL version="3.0"
LABEL description="ARK Survival Evolved dedicated game server, based on Ubuntu 24.04 LTS including steamcmd, arkmanager and cron."

# Bootstrapping variables
ENV SESSIONNAME="ARK Docker" \
    SERVERMAP="TheIsland" \
    SERVERPASSWORD="" \
    ADMINPASSWORD="adminpassword" \
    MAX_PLAYERS=60 \
    ARKCLUSTERID=cluster1 \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    SERVERPORT=27015 \
    STEAMPORT=7778 \
    RCONPORT=32330 \
    ENABLERCON=true \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    ARK_UID=1000 \
    ARK_GID=1000 \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

## Install dependencies
# ca-certificates/curl  : steamcmd download + arkmanager's own HTTPS calls
# git                   : clone ark-server-tools, weekly "upgrade-tools" cron job
# lsof, bzip2           : used by arkmanager itself
# cron                  : job scheduler (was "cronie" on CentOS)
# libcompress-raw-zlib-perl : Perl module arkmanager uses for backup handling (was "perl-Compress-Zlib")
# libc6-i386, lib32gcc-s1, lib32stdc++6 : 32-bit glibc runtime steamcmd/ShooterGameServer need
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      lsof \
      bzip2 \
      cron \
      libcompress-raw-zlib-perl \
      libc6-i386 \
      lib32gcc-s1 \
      lib32stdc++6 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -U -u $ARK_UID -s /bin/bash steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY ark-healthcheck.sh /home/steam/ark-healthcheck.sh
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN chmod 777 /home/steam/run.sh \
 && chmod 777 /home/steam/user.sh \
 && chmod 777 /home/steam/ark-healthcheck.sh \
 && git config --global advice.detachedHead false \
 && git clone -b $(git ls-remote --tags https://github.com/arkmanager/ark-server-tools.git | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | tail -n 1) --single-branch --depth 1 https://github.com/arkmanager/ark-server-tools.git /home/steam/ark-server-tools \
 && cd /home/steam/ark-server-tools \
 && bash netinstall.sh steam --bindir=/usr/bin \
 && (crontab -l 2>/dev/null; echo "* 3 * * Mon yes | arkmanager upgrade-tools >> /ark/log/arkmanager-upgrade.log 2>&1") | crontab - \
 && mkdir /ark \
 && chown steam /ark && chmod 755 /ark \
 && mkdir /home/steam/steamcmd \
 && cd /home/steam/steamcmd \
 && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

EXPOSE ${STEAMPORT} ${RCONPORT} ${SERVERPORT}
# Add UDP
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

# Volume to be exposed for this server
VOLUME  /ark

# Change the working directory to /ark
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]

HEALTHCHECK --interval=600s --timeout=60s --retries=2 --start-period=600s CMD /home/steam/ark-healthcheck.sh
