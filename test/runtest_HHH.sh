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
    #crun.py test_hh_trigger $MYOMCPATH/test/TSG-Run3Winter24GS-00016_fragment.py Run3Winter24 \
    crun.py run_hhh_trigger_custom_test $MYOMCPATH/test/HIG-Run3Winter24GS-00046-fragment.py Run3Winter24 --outEOS "/isilon/data/users/mstamenk/mc-for-trigger/samples/hhh6b-sm-test" --keepNANO --nevents_job 10 --njobs 1 --env --pileup_file 
elif [ "$QUEUE" == "condor_eos" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --keepMINI \
        --nevents_job 10 \
        --njobs 10 \
        --env
elif [ "$QUEUE" == "local" ]; then
    STARTDIR=$PWD
    mkdir testjob2
    cd testjob2
    source "$STARTDIR/../Run3Winter24/run.sh" test "$STARTDIR/HIG-Run3Winter24GS-00046-fragment.py" 10 1 1 "$STARTDIR/../Run3Winter24/pileupinput.dat"
    # Args are: name fragment_path nevents random_seed nthreads pileup_filelist
    cd $STARTDIR
fi