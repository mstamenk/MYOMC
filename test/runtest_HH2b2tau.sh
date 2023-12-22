#!/bin/bash
#crun.py test_Bu2PiJpsi2PiMuMu $MYOMCPATH/test/fragment.py RunIIFall18GS \
#    --gfalcp "gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/" \
#    --keepMini \
#    --nevents_job 5 \
#    --njobs 5 \
#    --env

QUEUE=${1}
if [ -z ${QUEUE} ]; then
    QUEUE=local
fi

if [ "$QUEUE" == "condor" ]; then
    #crun.py test_hh_trigger $MYOMCPATH/test/TSG-Run3Summer22wmLHEGS-00016_fragment.py Run3Summer22wmLHE \
    crun.py run_hh2b2tau_sm_Winter24 $MYOMCPATH/test/hh2b2tau-sm-fragment.py  Run3Winter24 --outEOS "/isilon/data/users/mstamenk/mc-for-trigger/Run3Winter24/hh2b2tau/" --keepNANO --nevents_job 500 --njobs 200 --env --pileup_file --seed_offset 3000
elif [ "$QUEUE" == "condor_eos" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --keepMINI \
        --nevents_job 10 \
        --njobs 10 \
        --env

elif [ "$QUEUE" == "local" ]; then
    STARTDIR=$PWD
    mkdir test_hh2b2tau_sm_trigger_custom_confDB
    cd test_hh2b2tau_sm_trigger_custom_confDB
    source "$STARTDIR/../Run3Winter24/run.sh" test "$STARTDIR/hh2b2tau-sm-fragment.py" 10 1 1 "$STARTDIR/../Run3Winter24/pileupinput.dat"
    # Args are: name fragment_path nevents random_seed nthreads pileup_filelist
    cd $STARTDIR
fi
