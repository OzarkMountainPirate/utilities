#!/bin/bash
#############################################################
## Name          : servicestop.sh
## Version       : 1.3
## Date          : 2026-07-04
## Original      : LHammonds - github.com/LHammonds/ubuntu-bash
## Maintainer    : OzarkMountainPirate - github.com/OzarkMountainPirate/utilities
## Compatibility : Ubuntu Server 24.04 LTS
## Requirements  : None
## Purpose       : Stop primary services.
## Run Frequency : As needed
## Exit Codes    : None
###################### CHANGE LOG ###########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ----------------------------
## 2013-01-08 1.0 LTH Created script.
## 2019-09-24 1.1 LTH Switched "service" to "systemctl" format.
## 2022-05-31 1.2 LTH Replaced echo statements with printf.
## 2026-07-04 1.3 OMP Forked from LHammonds; adapted & verified on 24.04.
#############################################################
## NOTE: Configure whatever services you need stopped here.
printf "Stopping services...\n"
#systemctl stop vsftpd
#systemctl stop nagios
#systemctl stop apache2
#systemctl stop mysql
sleep 1
