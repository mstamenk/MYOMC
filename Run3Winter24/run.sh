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
    PILEUP_FILELIST="dbs:/MinBias_TuneCP5_13p6TeV-pythia8/Run3Winter24GS-133X_mcRun3_2024_realistic_v7-v1/GEN-SIM" 
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
#export SCRAM_ARCH=el8_amd64_gcc10

source /cvmfs/cms.cern.ch/cmsset_default.sh
#if [ -r CMSSW_13_3_0/src ] ; then 
echo release CMSSW_13_3_0 already exists
cd CMSSW_13_3_0/src
eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_13_3_0" CMSSW_13_3_0
#    cd CMSSW_13_3_0/src
#    eval `scram runtime -sh`
#fi

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
    --python_filename "Run3Winter24wmLHE_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM,LHE \
    --fileout "file:Run3Winter24wmLHE_$NAME_$JOBINDEX.root" \
    --conditions 133X_mcRun3_2024_realistic_v8 \
    --beamspot Realistic25ns13p6TeVEarly2023Collision \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})" \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era Run3_2023 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS 
cmsRun "Run3Winter24wmLHE_${NAME}_cfg.py"
if [ ! -f "Run3Winter24wmLHE_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer22wmLHE_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# DIGIPremix
#export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
#if [ -r CMSSW_13_3_0/src ] ; then
echo release CMSSW_13_3_0 already exists
cd CMSSW_13_3_0/src
eval `scram runtime -sh`
#else
#    scram project -n "CMSSW_13_3_0" CMSSW_13_3_0
#    cd CMSSW_13_3_0/src
#    eval `scram runtime -sh`
#fi
cd $CMSSW_BASE/src
scram b


cd $TOPDIR
cmsDriver.py  \
    --python_filename "Run3Winter24Digi_${NAME}_cfg.py" \
	--eventcontent RAWSIM \
    --pileup 2023_LHC_Simulation_12p5h_9h_hybrid2p23 \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier GEN-SIM-RAW \
    --filein "file:Run3Winter24wmLHE_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Winter24Digi_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
	--conditions 133X_mcRun3_2024_realistic_v8 \
	--step DIGI,L1,DIGI2RAW,HLT:User \
	--geometry DB:Extended \
	--era Run3_2023 \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "Run3Winter24Digi_${NAME}_cfg.py"
if [ ! -f "Run3Winter24DRPremix_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Winter24DRPremix_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

cd $TOPDIR
cmsDriver.py  \
    --python_filename "Run3Winter24Reco_${NAME}_cfg.py" \
	--eventcontent RECOSIM,AODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier GEN-SIM-RECO,AODSIM \
    --filein "file:Run3Winter24Digi_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Winter24DRPremix_2_$NAME_$JOBINDEX.root" \
	--conditions 133X_mcRun3_2024_realistic_v8 \
	--step RAW2DIGI,L1Reco,RECO,RECOSIM \
	--geometry DB:Extended \
	--era Run3_2023 \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "Run3Winter24Reco_${NAME}_cfg.py"


# MiniAOD
#export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_3_0/src ] ; then
    echo release CMSSW_13_3_0 already exists
    cd CMSSW_13_3_0/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_3_0" CMSSW_13_3_0
    cd CMSSW_13_3_0/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Winter24MINIAODSIM_${NAME}_cfg.py" \
	--eventcontent MINIAODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier MINIAODSIM \
    --filein "file:Run3Winter24DRPremix_2_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Winter24MINIAODSIM_$NAME_$JOBINDEX.root" \
	--conditions 133X_mcRun3_2024_realistic_v8 \
	--step PAT \
	--geometry DB:Extended \
	--era Run3_2023 \
	--no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--mc \
    -n $NEVENTS
cmsRun "Run3Winter24MINIAODSIM_${NAME}_cfg.py"
if [ ! -f "Run3Winter24MINIAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Winter24MINIAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
#
## NanoAOD
#export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_3_0/src ] ; then
    echo release CMSSW_13_0_6 already exists
    cd CMSSW_13_3_0/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_6" CMSSW_13_3_0
    cd CMSSW_13_3_0/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "Run3Winter24NANOAODSIM_${NAME}_cfg.py" \
    --eventcontent NANOAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --filein "file:Run3Winter24MINIAODSIM_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Winter24NANOAODSIM_$NAME_$JOBINDEX.root" \
    --conditions 133X_mcRun3_2024_realistic_v8 \
    --step NANO \
    --era Run3_2023 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
cmsRun "Run3Winter24NANOAODSIM_${NAME}_cfg.py"
if [ ! -f "Run3Winter24NANOAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Winter24NANOAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi




