#!/bin/bash
# Some old stuff to ensure this is run on SLC6
#export SYSTEM_RELEASE=`cat /etc/redhat-release`
#if { [[ $SYSTEM_RELEASE == *"release 7"* ]]; }; then
#  echo "Running setup_env.sh on SLC6."
#  if { [[ $(hostname -s) = lxplus* ]]; }; then
#  	ssh -Y lxplus6 "cd $PWD; source setup_env.sh;"
#  elif { [[ $(hostname -s) = cmslpc* ]]; }; then
#  	ssh -Y cmslpc-sl6 "cd $PWD; source setup_env.sh;"
#  else
#  	echo "Not on cmslpc or lxplus, not sure what to do."
#  	return 1
#  fi
#  return 1
#fi

mkdir env
cd env
#export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh

scram project -n "CMSSW_13_3_0" CMSSW_13_3_0
cd CMSSW_13_3_0/src
eval `scram runtime -sh`
scram b
git cms-addpkg HLTrigger/Configuration
cp /isilon/data/users/mstamenk/mc-for-trigger/MYOMC/Run3Summer22wmLHE/env/CMSSW_13_3_0/src/HLTrigger/Configuration/python/HLT_User_cff.py HLTrigger/Configuration/python
scram b
cd ../../


tar -czvf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..
