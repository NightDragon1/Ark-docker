FROM centos:8
LABEL maintainer="NightDragon"

# Bootstrapping variables
ENV SESSIONNAME="ARK Docker" \
    SERVERMAP="TheIsland" \
    SERVERPASSWORD="" \
    ADMINPASSWORD="adminpassword" \
    MAX_PLAYERS=10 \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    SERVERPORT=27015 \
    STEAMPORT=7778 \
    RCONPORT=32330 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    ARK_UID=1000 \
    ARK_GID=1000 \
    TZ=UTC

## Ensure latest version
RUN yum upgrade -y

## Install dependencies
RUN yum -y install glibc.x86_64 libstdc++.x86_64 git lsof bzip2 cronie perl-Compress-Zlib \
 && yum clean all \
 && adduser -u $ARK_UID -s /bin/bash -U steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY ark-healthcheck.sh /home/steam/ark-healthcheck.sh
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN chmod 777 /home/steam/run.sh \
 && chmod 777 /home/steam/user.sh \
 && chmod 777 /home/steam/ark-healthcheck.sh \
 ## Always get the latest version of ark-server-tools
 && git clone --single-branch --depth 1 https://github.com/FezVrasta/ark-server-tools.git /home/steam/ark-server-tools \
 && cd /home/steam/ark-server-tools/tools \
 && bash install.sh steam --bindir=/usr/bin \
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
