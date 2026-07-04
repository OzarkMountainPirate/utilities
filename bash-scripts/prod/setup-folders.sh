#!/bin/bash
#############################################################
## Name          : setup-folders.sh
## Version       : 1.0
## Date          : 2026-07-04
## Original      : OzarkMountainPirate - github.com/OzarkMountainPirate/utilities
## Maintainer    : OzarkMountainPirate - github.com/OzarkMountainPirate/utilities
## Compatibility : Ubuntu Server 24.04 LTS
## Requirements  : root
## Purpose       : Create the /var/scripts folder skeleton.
## Run Frequency : Once, on a fresh server.
## Exit Codes    : 0 = success, 1 = not root
###################### CHANGE LOG ###########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ----------------------------
## 2026-07-04 1.0 OMP Created script.
#############################################################

if [ "$(id -u)" -ne 0 ]; then
  printf "This script must be run as root.\n" >&2
  exit 1
fi

for dir in common data prod test; do
  mkdir -p "/var/scripts/${dir}"
done
chown root:root -R /var/scripts
chmod 0755 -R /var/scripts
printf "Created /var/scripts/{common,data,prod,test}\n"
exit 0
