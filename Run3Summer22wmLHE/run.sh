# Run private production using Run3Summer settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 1 filelist:/path/to/pileup/list.txt
# 
# Batch example:
# python crun.py MyMCName /path/to/fragment.py --outEOS /store/user/myname/somefolder --keepMini --nevents_job 10000 --njobs 100 --env
# See crun.py for full options, especially regarding transfer of outputs.
# Make sure your gridpack is somewhere readable, e.g. EOS or CVMFS.
# Make sure to run setup_env.sh first to create a CMSSW tarball (have to patch the DR step to avoid taking forever to uniqify the list of 300K pileup files)
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    return 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    return 1
fi
FRAGMENT=$2
echo "Input arg 2 = $FRAGMENT"
FRAGMENT=$(readlink -e $FRAGMENT)
echo "After readlink fragment = $FRAGMENT"

if [ -z "$3" ]; then
    NEVENTS=100
else
    NEVENTS=$3
fi

if [ -z "$4" ]; then
    JOBINDEX=1
else
    JOBINDEX=$4
fi
RSEED=$((JOBINDEX + 1001))
SEED=$(($(date +%s) % 100 + 1))


if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX" 
else
    PILEUP_FILELIST="filelist:$6"
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

# wmLHE
export SCRAM_ARCH=el8_amd64_gcc10

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_6/src ] ; then 
    echo release CMSSW_13_0_6 already exists
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_6" CMSSW_13_0_6
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
fi

mkdir -pv $CMSSW_BASE/src/Configuration/GenProduction/python
cp $FRAGMENT $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py
if [ ! -f "$CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py" ]; then
    echo "Fragment copy failed"
    exit 1
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

#cat $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py

cmsDriver.py Configuration/GenProduction/python/fragment.py \
    --python_filename "Run3Summer22wmLHE_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM,LHE \
    --fileout "file:Run3Summer22wmLHE_$NAME_$JOBINDEX.root" \
    --conditions 130X_mcRun3_2023_realistic_v8 \
    --beamspot Realistic25ns13p6TeVEarly2022Collision \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})" \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era Run3 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS 
cmsRun "Run3Summer22wmLHE_${NAME}_cfg.py"
if [ ! -f "Run3Summer22wmLHE_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer22wmLHE_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# SIM
#export SCRAM_ARCH=slc7_amd64_gcc700
#source /cvmfs/cms.cern.ch/cmsset_default.sh
#if [ -r CMSSW_10_6_17_patch1/src ] ; then
#    echo release CMSSW_10_6_17_patch1 already exists
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
#    cd CMSSW_10_6_17_patch1/src
#    eval `scram runtime -sh`
#fi
#cd $CMSSW_BASE/src
#scram b
#cd $TOPDIR

#cmsDriver.py  \
#    --python_filename "RunIISummer20UL18SIM_${NAME}_cfg.py" \
#	--eventcontent RAWSIM \
#	--customise Configuration/DataProcessing/Utils.addMonitoring \
#	--datatier GEN-SIM \
#    --fileout "file:RunIISummer20UL18SIM_$NAME_$JOBINDEX.root" \
#	--conditions 106X_upgrade2018_realistic_v11_L1v1 \
#	--beamspot Realistic25ns13TeVEarly2018Collision \
#	--step SIM \
#	--geometry DB:Extended \
#    --filein "file:RunIISummer20UL18wmLHE_$NAME_$JOBINDEX.root" \
#	--era Run2_2018 \
#	--runUnscheduled \
#	--no_exec \
#	--mc \
#    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
#    -n $NEVENTS
#cmsRun "RunIISummer20UL18SIM_${NAME}_cfg.py"
#if [ ! -f "RunIISummer20UL18SIM_$NAME_$JOBINDEX.root" ]; then
#    echo "RunIISummer20UL18SIM_$NAME_$JOBINDEX.root not found. Exiting."
#    return 1
#fi


# DIGIPremix
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_6/src ] ; then
    echo release CMSSW_13_0_6 already exists
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_6" CMSSW_13_0_6
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b


cd $TOPDIR
cmsDriver.py  \
    --python_filename "Run3Summer22DIGIPremix_${NAME}_cfg.py" \
	--eventcontent PREMIXRAW \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier GEN-SIM-RAW \
    --filein "file:Run3Summer22wmLHE_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22DRPremix_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
	--conditions 130X_mcRun3_2023_realistic_v8 \
	--step DIGI,DATAMIX,L1,DIGI2RAW,HLT \
	--procModifiers premix_stage2,siPixelQualityRawToDigi \
	--geometry DB:Extended \
	--datamix PreMix \
	--era Run3 \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "Run3Summer22DIGIPremix_${NAME}_cfg.py"
if [ ! -f "Run3Summer22DRPremix_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22DRPremix_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

cd $TOPDIR
cmsDriver.py  \
cmsDriver.py  \
    --python_filename "Run3Summer22DRPremix_${NAME}_cfg.py" \
	--eventcontent AODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier AODSIM \
    --filein "file:Run3Summer22DRPremix_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22DRPremix_2_$NAME_$JOBINDEX.root" \
	--conditions 130X_mcRun3_2023_realistic_v8 \
	--step RAW2DIGI,L1Reco,RECO,RECOSIM \
	--geometry DB:Extended \
	--era Run3 \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "Run3Summer22DRPremix_${NAME}_cfg.py"
if [ ! -f "Run3Summer22DRPremix_2_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22DRPremix_2_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

# MiniAOD
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_6/src ] ; then
    echo release CMSSW_13_0_6 already exists
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_6" CMSSW_13_0_6
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Summer22MINIAODSIM_${NAME}_cfg.py" \
	--eventcontent MINIAODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier MINIAODSIM \
    --filein "file:Run3Summer22DRPremix_2_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22MINIAODSIM_$NAME_$JOBINDEX.root" \
	--conditions 130X_mcRun3_2023_realistic_v8 \
	--step PAT \
	--geometry DB:Extended \
	--era Run3 \
	--no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--mc \
    -n $NEVENTS
cmsRun "Run3Summer22MINIAODSIM_${NAME}_cfg.py"
if [ ! -f "Run3Summer22MINIAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22MINIAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
#
## NanoAOD
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_6/src ] ; then
    echo release CMSSW_13_0_6 already exists
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_6" CMSSW_13_0_6
    cd CMSSW_13_0_6/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Summer22NANOAODSIM_${NAME}_cfg.py" \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --filein "file:Run3Summer22MINIAODSIM_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22NANOAODSIM_$NAME_$JOBINDEX.root" \
    --conditions 130X_mcRun3_2023_realistic_v8 \
    --step NANO \
    --era Run3,run3_nanoAOD_124 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
cmsRun "Run3Summer22NANOAODSIM_${NAME}_cfg.py"
if [ ! -f "Run3Summer22NANOAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22NANOAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi




