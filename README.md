![Shield.IO Badger](https://img.shields.io/docker/cloud/build/nightdragon1/ark-docker) ![Shield.IO Badger](https://img.shields.io/docker/pulls/nightdragon1/ark-docker)  [![](https://images.microbadger.com/badges/license/nightdragon1/ark-docker.svg)](https://microbadger.com/images/nightdragon1/ark-docker "Get your own license badge on microbadger.com")

# ARK: Survival Evolved - Docker

Docker build for managing an ARK: Survival Evolved server.

This image uses [Ark Server Tools](https://github.com/FezVrasta/ark-server-tools) to manage an ark server and is forked from [boerngenschmidt/Ark-docker](https://github.com/boerngen-schmidt/Ark-docker)

*If you use an old volume, get the new arkmanager.cfg in the template directory.*  
__Don't forget to use `docker pull NightDragon1/ark-docker` to get the latest version of the image__

__IMPORTED INFO for those who wanna migrate!__ 
If you haven't been using this docker-image before, just go ahead creating it like explained in "__Usage__".
If you have been using another image before, like boerngenschmidt/Ark-docker, you'll have to two do things:
1. Remove the old container instance using __docker rm__....
2. Recreate the new container instance with the same parameters as before, optionally: add/set the new ENVIRONMENT variable "RCONPORT" to your __docker create__
3. In case you are using your existing arkamanger.cfg, add the following lines to your file:
```
ark_Port=${STEAMPORT}
ark_QueryPort=${SERVERPORT}
ark_RCONEnabled="True"
ark_RCONPort=${RCONPORT}
```

## Features
 - Easy install (no steamcmd / lib32... to install)
 - Use Ark Server Tools : update/install/start/backup/rcon/mods
 - Easy crontab configuration
 - Easy access to ark config file
 - Mods handling (via Ark Server Tools)
 - `Docker stop` is a clean stop 
 - Auto upgrading of arkmanager
 - An Up to date Docker Images for ARK-Docker
 - Docker Healthcheck

## Usage
Fast & Easy server setup :   
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -e SESSIONNAME=myserver -e ADMINPASSWORD="mypasswordadmin" --name ark nightdragon1/ark-docker`

You can map the ark volume to access config files :  
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -e SESSIONNAME=myserver -v /my/path/to/ark:/ark --name ark nightdragon1/ark-docker`  
Then you can edit */my/path/to/ark/arkmanager.cfg* (the values override GameUserSetting.ini) and */my/path/to/ark/[GameUserSetting.ini/Game.ini]*

You can manager your server with rcon if you map the rcon port (you can rebind the rcon port with docker):  
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -p 32330:32330  -e SESSIONNAME=myserver --name ark nightdragon1/ark-docker`  

You can change server and steam port to allow multiple servers on same host:  
*(You can't just rebind the port with docker. It won't work, you need to change STEAMPORT, SERVERPORT & RCONPORT variable)*
`docker run -d -p 7779:7779 -p 7779:7779/udp -p 27016:27016 -p 27016:27016/udp -p 32331:32330  -e SESSIONNAME=myserver2 -e SERVERPORT=27016 -e STEAMPORT=7779 --name ark2 nightdragon1/ark-docker`  

You can check your server with :  
`docker exec ark arkmanager status` 

You can manually update your mods:  
`docker exec ark arkmanager update --update-mods` 

You can manually update your server:  
`docker exec ark arkmanager update --force` 

You can force save your server :  
`docker exec ark arkmanager saveworld` 

You can backup your server :  
`docker exec ark arkmanager backup` 

You can upgrade Ark Server Tools :  
`docker exec ark arkmanager upgrade-tools` 

You can use rcon command via docker :  
`docker exec ark arkmanager rconcmd ListPlayers`  
*Full list of available command [here](http://steamcommunity.com/sharedfiles/filedetails/?id=454529617&searchtext=admin)*

__You can check all available command for arkmanager__ [here](https://github.com/FezVrasta/ark-server-tools/blob/master/README.md)

### Crontab - Job automation
You can easily configure automatic update and backup.  
If you edit the file `/my/path/to/ark/crontab` you can add your crontab job.  
For example :  
```
# Update the server every hours  
0 * * * * arkmanager update --warn --update-mods >> /ark/log/crontab.log 2>&1    
# Backup the server each day at 00:00  `  
0 0 * * * arkmanager backup >> /ark/log/crontab.log 2>&1
```  
*You can check [this website](http://www.unix.com/man-page/linux/5/crontab/) for more information on cron.*

After updating the `/my/path/to/ark/crontab` please run the command   
`docker exec ark crontab -u steam /ark/crontab`

To add mods, you only need to change the variable ark_GameModIds in *arkmanager.cfg* with a list of your modIds (like this  `ark_GameModIds="987654321,1234568"`). If UPDATEONSTART is enable, just restart your docker or use `docker exec ark arkmanager update --update-mods`.

## Recommended Usages

### Simple container
- First run  
 ```Bash
 docker run -it --name ark \
  -p 7778:7778 -p 7778:7778/udp \
  -p 27015:27015 -p 27015:27015/udp \
  -p 32330:32330 \
  -e SESSIONNAME=myserver \
  -e ADMINPASSWORD="mypasswordadmin" \
  -e TZ=Europe/Vienna \
  -v /my/path/to/ark:/ark \
  Nightdragon1/ark-docker
  ```
- Wait for ark to be downloaded installed and launched, then Ctrl+C to stop the server.
- Edit */my/path/to/ark/GameUserSetting.ini and Game.ini*
- Edit */my/path/to/ark/arkserver.cfg* to add mods and configure warning time.
- Add auto update every day and autobackup by editing */my/path/to/ark/crontab*. [See](#crontab---job-automation)
- Start the container `docker start ark`
- Check your server with : `docker exec ark arkmanager status` 

### Docker-Compose
- Modify [docker-compose.yml](docker-compose.yml)
- run `docker-compose up -d ark`

## Variables
+ __SESSIONNAME__ : Name of your ark server (default : "Ark Docker")
+ __SERVERMAP__ : Map of your ark server (default : "TheIsland")
+ __SERVERPASSWORD__ : Password of your ark server (default : "")
+ __ADMINPASSWORD__ : Admin password of your ark server (default : "adminpassword")
+ __ENABLERCON__ : valid falues are __true__ and __false__ . If set to true, RCON will be enabled
+ __SERVERPORT__ : Ark server port (default : 27015)
+ __STEAMPORT__ : Steam server port (default : 7778)
+ __RCONPORT__ : Use to set the RCON port  (default : 32330)
+ __MAX_PLAYERS__ : Number of maximum players (default : 40)
+ __BACKUPONSTART__ : Backup the server when the container is started. 0: no backup (default : 1)
+ __UPDATEPONSTART__ : Update the server when the container is started. 0: no update (default : 1)
+ __BACKUPONSTOP__ : Backup the server when the container is stopped. 0: no backup (default : 1)
+ __WARNONSTOP__ : Warn the players before the container is stopped. 0: no warning (default : 1)
+ __TZ__ : container timezone (for crontab). (default : "UTC").
+ __ARK_UID__ : ARK_UID of the user used. Owner of the volume /ark (default : 1000)
+ __ARK_GID__ : ARK_GID of the user used. Owner of the volume /ark (default : 1000)
+ __ARKCLUSTERID__ : A string to configure the cluster ID (used for cross server traveling)

### Gameplay rates (GameUserSettings.ini, applied via launch parameters on every start)
+ __GAMERULE_XP_MULTIPLIER__ : Experience gain multiplier (default : 4.0)
+ __GAMERULE_TAMING_MULTIPLIER__ : Taming speed multiplier (default : 8.0)
+ __GAMERULE_HARVEST_MULTIPLIER__ : Harvest amount multiplier (default : 5.0)
+ __GAMERULE_DAY_TIME_SPEED_SCALE__ : Day cycle speed scale (default : 0.4871104)
+ __GAMERULE_NIGHT_TIME_SPEED_SCALE__ : Night cycle speed scale (default : 0.5313034)
+ __GAMERULE_DINO_DECAY_MULTIPLIER__ : Wild/tamed dino decay speed on PvE (default : 0.8)
+ __GAMERULE_STRUCTURE_DECAY_MULTIPLIER__ : Structure decay speed on PvE (default : 5.0)
+ __GAMERULE_PVP_STRUCTURE_DECAY__ : Enable structure decay on PvP servers, valid values __true__/__false__ (default : true)
+ __GAMERULE_PVP_DINO_DECAY__ : Enable dino decay on PvP servers, valid values __true__/__false__ (default : true)
+ __GAMERULE_PREVENT_OFFLINE_PVP__ : Enable offline raid protection on PvP servers (default : true)
+ __GAMERULE_PREVENT_OFFLINE_PVP_INTERVAL__ : Seconds offline before offline raid protection kicks in (default : 900)
+ __GAMERULE_MAX_PLATFORM_SADDLE_STRUCTURE_LIMIT__ : Max structures per platform saddle (default : 20)
+ __GAMERULE_PER_PLATFORM_MAX_STRUCTURES_MULTIPLIER__ : Multiplier for the per-platform structure limit (default : 4.0)
+ __GAMERULE_AUTO_DESTROY_DECAYED_DINOS__ : Automatically remove fully decayed dinos (default : true)
+ __GAMERULE_SHOW_FLOATING_DAMAGE_TEXT__ : Show floating damage numbers (default : true)

### Breeding / difficulty (Game.ini, regenerated fresh on every start)
+ __GAMEINI_OVERRIDE_DIFFICULTY__ : Overrides engine difficulty offset, raises max wild dino level/loot quality (default : 5.0)
+ __GAMEINI_RESOURCE_NO_REPLENISH_RADIUS__ : Radius around structures where resources won't respawn (default : 0.8)
+ __GAMEINI_ALLOW_ANYONE_BABY_IMPRINT_CUDDLE__ : Allow any tribe member to cuddle/imprint, not just the imprinter (default : true)
+ __GAMEINI_POOP_INTERVAL_MULTIPLIER__ : Multiplier for how often dinos/players need to poop (default : 2.5)
+ __GAMEINI_EGG_HATCH_SPEED_MULTIPLIER__ : Egg hatch speed multiplier (default : 1.5)
+ __GAMEINI_BABY_MATURE_SPEED_MULTIPLIER__ : Baby maturation speed multiplier (default : 2.0)
+ __GAMEINI_MATING_INTERVAL_MULTIPLIER__ : Multiplier for the interval between matings (default : 2.0)
+ __GAMEINI_FORCE_ALL_STRUCTURE_LOCKING__ : Force newly placed structures to be locked by default (default : true)
+ __GAMEINI_FAST_DECAY_UNSNAPPED_CORE_STRUCTURES__ : Fast-decay core structures (foundations/pillars) not snapped to anything (default : true)
+ __GAMEINI_DESTROY_UNCONNECTED_WATER_PIPES__ : Auto-destroy water pipes not connected to an intake/tap (default : true)
+ __GAMEINI_FAST_DECAY_INTERVAL__ : Decay interval in seconds used by the two fast-decay settings above (default : 64800)

## Volumes
+ __/ark__ : Working directory :
    + /ark/server : Server files and data.
    + /ark/log : logs
    + /ark/backup : backups
    + /ark/arkmanager.cfg : config file for Ark Server Tools
    + /ark/crontab : crontab config file
    + /ark/Game.ini : ark game.ini config file
    + /ark/GameUserSetting.ini : ark gameusersetting.ini config file
    + /ark/template : Default config files
    + /ark/template/arkmanager.cfg : default config file for Ark Server Tools
    + /ark/template/crontab : default config file for crontab
    + /ark/staging : default directory if you use the --downloadonly option when updating.

## Expose
+ Port : __STEAMPORT__ : Steam port (default: 7778)
+ Port : __SERVERPORT__ : server port (default: 27015)
+ Port : __RCONPORT__ : rcon port (default: 32330)

## Known issues
Currently none

## Changelog
+ 1.0 : 
  - Initial image : works with Ark Server tools 1.3
  - Add auto-update & auto-backup  
+ 1.1 :  
  - Works with Ark Server Tools 1.4 [See changelog here](https://github.com/FezVrasta/ark-server-tools/releases/tag/v1.4)
  - Handle mods && auto update mods
+ 1.2 :
  - Remove variable AUTOBACKUP & AUTOUPDATE 
  - Remove variable WARNMINUTE (can now be find in arkmanager.cfg)
  - Add crontab support
  - You can now config crontab with the file /your/ark/path/crontab
  - Add template directory with default config files.
  - Add documentation on TZ variable.
+ 1.3 :
  - Add BACKUPONSTOP to backup the server when you stop the server (thanks to [fkoester](https://github.com/fkoester))
  - Add WARNONSTOP to add warning message when you stop the server (default: 60 min)
  - Works with Ark Server Tools v1.5
    - Compressing backups so they take up less space
    - Downloading updates to a staging directory before applying
    - Added support for automatically updating on restart
    - Show a spinner when updating
  - Add UID & GID to set the uid & gid of the user used in the container (and permissions on the volume /ark)
+ 1.4 : **Maintainer switch: boerngen-schmidt/Ark-docker**
  - changed from ubuntu to centOS 7
  - added timezone support
  - image now always pulls latest Ark Server Tools
  - renamed NBPLAYERS to MAX_PLAYERS
  - added prefixc ARK_ to UID & GID to not have conflicts with arkmanager
  - added auto upgrading of arkmanager
+ 1.5 :
  - fixed arkmanager upgrade
+ 1.6: **Maintainer switch: NightDragon1/Ark-docker**
  - Initial from boerngen-schmidt/Ark-docker
  - Fixed some bugs
  - Updated from CentOS 7 to CentOS 8
  - Added some modifications to the default config
  - Added RCON Port ENV-Vars
+ 1.7:
  - Added Docker-Healthcheck (status becomes unhealthy while arkmanager runns update)
+ 1.7.1:
  - Changed Healthcheck for "Server listening" instead of "Server running"
+ 1.7.2:
  - Fixed Healthcheck
+ 1.7.3:
  - Updated compose-file
  - Repository Cleanup
+ 1.7.4:
  - Update to run.sh
+ 1.8:
  - Added "arkmanager restart" to health check if failed
+ 1.9
  - Update to use new git repository of arkmanager
+ 2.0
  - Added crudini to edit Game.ini oder GameUserSettings.ini
+ 2.1
  - Made clusterid configureable via docker environment variable
  - Made RCON enabled configurable via docker environment variable 
+ 2.2
  - Bugfix release regaridng "disk write error" of steamcmd
+ 2.3
  - Removed ARK Mod "ACM" to be configured per default as it's not compatible anymore with Gen2 and not maintaned too
+ 2.4
  - Bugfix: Fixed an issue where the RCON-Enabled setting from Docker ENV was not properly passed over to the arkmanager.cfg
+ 3.0
  - Updates: Switch to Ubuntu 24.04 and general modernizations.
  - Added Some Mods per defaults (Awesom Admin, S+. Platforms +, ... see config)
+ 3.1
  - Added some more Game_Variables. The defaults are the ones I use.
