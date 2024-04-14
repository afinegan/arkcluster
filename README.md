# ARK: Survival Evolved - Docker Cluster

Docker build for managing an __ARK: Survival Evolved__ server cluster.

This image uses [Ark Server Tools](https://github.com/arkmanager/ark-server-tools) to manage an ark server and is forked from [boerngen-schmidt/Ark-docker](https://hub.docker.com/r/boerngenschmidt/ark-docker/).

*If you use an old volume, get the new arkmanager.cfg in the template directory.*

__Don't forget to use `docker pull r15ch13/arkcluster` to get the latest version of the image__

## Features
 - Easy install (no steamcmd / lib32... to install)
 - Easy access to ark config file
 - Mods handling (via Ark Server Tools)
 - `docker stop` is a clean stop
 - Auto upgrading of arkmanager

## Usage
Fast & Easy cluster setup via docker compose:

```yaml
version: "3"

services:
  island:
    image: r15ch13/arkcluster:latest
    deploy:
      mode: global
    environment:
      CRON_AUTO_UPDATE: "0 */3 * * *"
      CRON_AUTO_BACKUP: "0 */1 * * *"
      UPDATEONSTART: 1
      BACKUPONSTART: 1
      BACKUPONSTOP: 1
      WARNONSTOP: 1
      TZ: "UTC"
      MAX_BACKUP_SIZE: 500
      SERVERMAP: "TheIsland"
      SESSION_NAME: "ARK Cluster TheIsland"
      MAX_PLAYERS: 15
      RCON_ENABLE: "True"
      QUERY_PORT: 15000
      GAME_PORT: 15002
      RCON_PORT: 15003
      SERVER_PVE: "False"
      SERVER_PASSWORD: ""
      ADMIN_PASSWORD: "keepmesecret"
      SPECTATOR_PASSWORD: "keepmesecret"
      MODS: "731604991"
      CLUSTER_ID: "myclusterid"
      GAME_USERSETTINGS_INI_PATH: "/cluster/myclusterid.config.GameUserSettings.ini"
      GAME_INI_PATH: "/cluster/myclusterid.config.Game.ini"
      KILL_PROCESS_TIMEOUT: 300
      KILL_ALL_PROCESSES_TIMEOUT: 300
    volumes:
      - data_island:/ark
      - cluster:/cluster
    ports:
      - "15000-15003:15000-15003/udp"

  valguero:
    image: r15ch13/arkcluster:latest
    deploy:
      mode: global
    environment:
      CRON_AUTO_UPDATE: "15 */3 * * *"
      CRON_AUTO_BACKUP: "15 */1 * * *"
      UPDATEONSTART: 1
      BACKUPONSTART: 1
      BACKUPONSTOP: 1
      WARNONSTOP: 1
      TZ: "UTC"
      MAX_BACKUP_SIZE: 500
      SERVERMAP: "Valguero_P"
      SESSION_NAME: "ARK Cluster Valguero"
      MAX_PLAYERS: 15
      RCON_ENABLE: "False"
      QUERY_PORT: 15010
      GAME_PORT: 15012
      RCON_PORT: 15013
      SERVER_PVE: "False"
      SERVER_PASSWORD: ""
      ADMIN_PASSWORD: "keepmesecret"
      SPECTATOR_PASSWORD: "keepmesecret"
      MODS: "731604991"
      CLUSTER_ID: "myclusterid"
      GAME_USERSETTINGS_INI_PATH: "/cluster/myclusterid.config.GameUserSettings.ini"
      GAME_INI_PATH: "/cluster/myclusterid.config.Game.ini"
      KILL_PROCESS_TIMEOUT: 300
      KILL_ALL_PROCESSES_TIMEOUT: 300
    volumes:
      - data_valguero:/ark
      - cluster:/cluster
    ports:
      - "15010-15013:15010-15013/udp"

volumes:
  data_island:
  data_valguero:
  cluster:
```

## Volumes
+ __/ark__ : Working directory :
    + `/ark/server` : Server files and data.
    + `/ark/log` : logs
    + `/ark/backup` : backups
    + `/ark/arkmanager.cfg` : config file for Ark Server Tools
    + `/ark/crontab` : crontab config file
    + `/ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini` : ark Game.ini config file
    + `/ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSetting.ini` : ark GameUserSetting.ini config file
    + `/ark/template` : Default config files
    + `/ark/template/arkmanager.cfg` : default config file for Ark Server Tools
    + `/ark/template/crontab` : default config file for crontab
    + `/ark/staging` : default directory if you use the --downloadonly option when updating.
+ __/cluster__ : Cluster volume to share with other instances
    + `/cluster/myclusterid.Game.ini` : ark Game.ini config file which will be copied on every start
    + `/cluster/myclusterid.GameUserSetting.ini` : ark GameUserSetting.ini config file which will be copied on every start

## Known issues
Currently none
