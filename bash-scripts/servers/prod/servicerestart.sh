#!/bin/bash
#############################################################
## Name          : servicerestart.sh
## Version       : 1.2
## Date          : 2026-07-04
## Original      : LHammonds - github.com/LHammonds/ubuntu-bash
## Maintainer    : OzarkMountainPirate - github.com/OzarkMountainPirate/utilities
## Compatibility : Ubuntu Server 24.04 LTS
## Requirements  : None
## Purpose       : Stop/Start primary services.
## Run Frequency : As needed
## Exit Codes    : None
###################### CHANGE LOG ###########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2013-01-08 1.0 LTH Created script.
## 2018-04-19 1.1 LTH Spit stop/start code into individual scripts.
## 2026-07-04 1.2 OMP Forked from LHammonds; adapted & verified on 24.04.
#############################################################
## Import standard variables and functions. ##
source /var/scripts/common/standard.conf
clear
${ScriptDir}/prod/servicestop.sh
${ScriptDir}/prod/servicestart.sh
