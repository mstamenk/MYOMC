#!/bin/bash
source env.sh
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" "Run3Summer22wmLHE" )
for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd $CAMPAIGN
	source setup_env.sh
	cd $TOPDIR
done
