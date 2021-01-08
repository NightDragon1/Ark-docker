#!/bin/sh

# Change the ARK_UID if needed
if [ ! "$(id -u steam)" -eq "$ARK_UID" ]; then 
	echo "Changing steam uid to $ARK_UID."
	usermod -o -u "$ARK_UID" steam ; 
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$ARK_GID" ]; then 
	echo "Changing steam gid to $ARK_GID."
	groupmod -o -g "$ARK_GID" steam ; 
fi

# Set Timezone
if [ -f /usr/share/zoneinfo/${TZ} ]; then
    echo "Setting timezone to '${TZ}'..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
else
    echo "Timezone '${TZ}' does not exist!"
fi

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam

# avoid error message when su -p (we need to read the /root/.bash_rc )
chmod -R 777 /root/

# Starting cron
echo "Starting cron service..."
cron

# Launch run.sh with user steam
su -p -c /home/steam/run.sh steam
