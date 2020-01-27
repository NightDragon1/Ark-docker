#!/bin/bash
##########################################
# ARK-Docker Health-Check-Script via     #
# arkmanager                             #
# Author: R. Holzknecht aka NightDragon  #
##########################################

export arkrunning=$(arkmanager status | sed -n 2p | sed -e 's/\x1b\[[0-9;]*m//g'  | tr -d ' ' | cut -d ':' -f2)

if [[ $arkrunning  == "Yes" ]]; then
  echo 0
else
  echo 1
fi

unset arkrunning
