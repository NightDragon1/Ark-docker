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

# Regenerate Game.ini from GAMEINI_* envs (Game.ini-only settings, not settable
# via arkmanager's ark_<Name> launch-param mechanism - see arkGameIniFile in
# arkmanager.cfg). Rebuilt fresh on every start, same as everything else.
echo "Writing Game.ini overrides..."
{
	echo "[/script/shootergame.shootergamemode]"
	echo "ResourceNoReplenishRadiusStructures=${GAMEINI_RESOURCE_NO_REPLENISH_RADIUS}"
	echo "AllowAnyoneBabyImprintCuddle=${GAMEINI_ALLOW_ANYONE_BABY_IMPRINT_CUDDLE}"
	echo "PoopIntervalMultiplier=${GAMEINI_POOP_INTERVAL_MULTIPLIER}"
	echo "EggHatchSpeedMultiplier=${GAMEINI_EGG_HATCH_SPEED_MULTIPLIER}"
	echo "BabyMatureSpeedMultiplier=${GAMEINI_BABY_MATURE_SPEED_MULTIPLIER}"
	echo "MatingIntervalMultiplier=${GAMEINI_MATING_INTERVAL_MULTIPLIER}"
	echo "ForceAllStructureLocking=${GAMEINI_FORCE_ALL_STRUCTURE_LOCKING}"
	echo "FastDecayUnsnappedCoreStructures=${GAMEINI_FAST_DECAY_UNSNAPPED_CORE_STRUCTURES}"
	echo "DestroyUnconnectedWaterPipes=${GAMEINI_DESTROY_UNCONNECTED_WATER_PIPES}"
	echo "FastDecayInterval=${GAMEINI_FAST_DECAY_INTERVAL}"
	# No safe "vanilla" value exists for this one (it force-overrides the engine's
	# own difficulty scaling) - only emit it if explicitly set, otherwise the
	# engine's normal DifficultyOffset-based behaviour applies untouched.
	if [ -n "${GAMEINI_OVERRIDE_DIFFICULTY}" ]; then
		echo "OverrideOfficialDifficulty=${GAMEINI_OVERRIDE_DIFFICULTY}"
	fi
} > /ark/Game.ini.generated

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
