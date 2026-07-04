#!/bin/bash
#############################################################
## Name          : servicestart.sh
## Version       : 1.3
## Date          : 2026-07-04
## Original      : LHammonds - github.com/LHammonds/ubuntu-bash
## Maintainer    : OzarkMountainPirate - github.com/OzarkMountainPirate/utilities
## Compatibility : Ubuntu Server 24.04 LTS
## Requirements  : None
## Purpose       : Start primary services.
## Run Frequency : As needed
## Exit Codes    : None
###################### CHANGE LOG ###########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2018-04-19 1.0 LTH Created script.
## 2019-09-24 1.1 LTH Switched "service" to "systemctl" format.
## 2022-05-31 1.2 LTH Replaced echo statements with printf.
## 2026-07-04 1.3 OMP Forked from LHammonds; adapted & verified on 24.04.
#############################################################
## NOTE: Add whatever services you need started here.
printf "Starting services...\n"
#systemctl start mysql
#systemctl start apache2
#systemctl start nagios
#systemctl start vsftpd
sleep 1
