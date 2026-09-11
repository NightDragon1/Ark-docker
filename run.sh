#!/usr/bin/env bash
echo "###########################################################################"
echo "# Ark Server - " `date`
echo "# UID $ARK_UID - GID $ARK_GID"
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "[Backup on stop]"
		arkmanager backup
	fi
	if [ ${WARNONSTOP} -eq 1 ];then 
	    arkmanager stop --warn
	else
	    arkmanager stop
	fi
	exit
}

# Change working directory to /ark to allow relative path
cd /ark

# Add a template directory to store the last version of config file
[ ! -d /ark/template ] && mkdir /ark/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /ark/template/arkmanager.cfg
cp /home/steam/crontab /ark/template/crontab
# Creating directory tree && symbolic link
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /ark/arkmanager.cfg
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging
[ ! -L /ark/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
[ ! -L /ark/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
[ ! -f /ark/crontab ] && cp /ark/template/crontab /ark/crontab

if [ ! -d /ark/server  ] || [ ! -f /ark/server/version.txt ];then
	echo "No game files found. Installing..."
	mkdir -p /ark/server/steamapps
	mkdir -p /ark/server/ShooterGame/Saved/SavedArks
	mkdir -p /ark/server/ShooterGame/Content/Mods
	mkdir -p /ark/server/ShooterGame/Binaries/Linux/
	touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
	arkmanager install --verbose
	# Create mod dir
else
	if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then
		echo "[Backup]"
		arkmanager backup
	fi
fi

# Installing crontab for user steam
echo "Loading crontab..."
cat /ark/crontab | crontab -

# Apply GAMEINI_* envs into the server's real Game.ini, in place - never a
# wholesale overwrite. On the very first ever start the file doesn't exist
# yet (the engine only creates it once it boots, further down via
# "arkmanager start"), so we deliberately do nothing and let the engine
# create it untouched - our overrides simply won't apply on this one boot.
# From the next restart onward the file exists, so we patch just our keys
# into it: existing keys get their value replaced in place, missing keys
# get appended under the section header, everything else already in the
# file (manual edits, mod-added settings) is left exactly as-is.
GAMEINI_TARGET="/ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini"
GAMEINI_SECTION='[/script/shootergame.shootergamemode]'

if [ -f "$GAMEINI_TARGET" ]; then
	echo "Updating Game.ini overrides..."
	grep -qxF "$GAMEINI_SECTION" "$GAMEINI_TARGET" || printf '%s\n' "$GAMEINI_SECTION" >> "$GAMEINI_TARGET"

	set_gameini_key() {
		local key="$1" val="$2"
		[ -z "$val" ] && return 0
		if grep -q "^${key}=" "$GAMEINI_TARGET"; then
			sed -i "s|^${key}=.*|${key}=${val}|" "$GAMEINI_TARGET"
		else
			local ln
			ln=$(grep -nxF "$GAMEINI_SECTION" "$GAMEINI_TARGET" | head -n1 | cut -d: -f1)
			sed -i "${ln}a ${key}=${val}" "$GAMEINI_TARGET"
		fi
	}

	set_gameini_key "ResourceNoReplenishRadiusStructures" "${GAMEINI_RESOURCE_NO_REPLENISH_RADIUS}"
	set_gameini_key "AllowAnyoneBabyImprintCuddle"        "${GAMEINI_ALLOW_ANYONE_BABY_IMPRINT_CUDDLE}"
	set_gameini_key "PoopIntervalMultiplier"              "${GAMEINI_POOP_INTERVAL_MULTIPLIER}"
	set_gameini_key "EggHatchSpeedMultiplier"             "${GAMEINI_EGG_HATCH_SPEED_MULTIPLIER}"
	set_gameini_key "BabyMatureSpeedMultiplier"           "${GAMEINI_BABY_MATURE_SPEED_MULTIPLIER}"
	set_gameini_key "MatingIntervalMultiplier"            "${GAMEINI_MATING_INTERVAL_MULTIPLIER}"
	set_gameini_key "ForceAllStructureLocking"            "${GAMEINI_FORCE_ALL_STRUCTURE_LOCKING}"
	set_gameini_key "FastDecayUnsnappedCoreStructures"    "${GAMEINI_FAST_DECAY_UNSNAPPED_CORE_STRUCTURES}"
	set_gameini_key "DestroyUnconnectedWaterPipes"        "${GAMEINI_DESTROY_UNCONNECTED_WATER_PIPES}"
	set_gameini_key "FastDecayInterval"                   "${GAMEINI_FAST_DECAY_INTERVAL}"
	# No safe "vanilla" value exists for this one (it force-overrides the
	# engine's own difficulty scaling) - only set it if explicitly configured,
	# otherwise the engine's normal DifficultyOffset-based behaviour applies.
	set_gameini_key "OverrideOfficialDifficulty"          "${GAMEINI_OVERRIDE_DIFFICULTY}"
else
	echo "Game.ini not found yet (first boot) - GAMEINI_* overrides will apply starting with the next restart."
fi

# Launching ark server
if [ $UPDATEONSTART -eq 0 ]; then
	arkmanager start --noautoupdate  --verbose	
else
	arkmanager start --verbose	
fi


# Stop server in case of signal INT or TERM
echo "Waiting..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
