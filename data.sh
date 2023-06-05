#!/bin/bash
#########################################################################################################
source /workloads/SEP/sep_vars.sh

function pause(){
   read -p "$*"
}


DC_TYPE=$1
OUTDIR=$2
RUNNUM=$3
R_TYPE=$4
JVM=$5
EMON_EVENTS_TXT_PREFIX=$6


echo `pwd`
date
echo "Type of collection: $DC_TYPE"
echo "Output Directory: $OUTDIR"
echo "Run number is: $RUNNUM"
echo "Run Type is: $R_TYPE"


if [ "$R_TYPE" = "PRESET" ]; then
   LookForTag="Ramping up completed"
   echo "Looking for: $LookForTag"
elif [ "$R_TYPE" == "LOADLEVEL" ]; then
  LookForTag="Performing load levels"
   echo "Looking for: $LookForTag"

fi



# create data collection stuff  (SEP, EMON, ALL)
sleep 10
#SA=10000



tail -f  $OUTDIR/controller.out | while read line ; do
#      echo "$line"
      echo "$line" | grep "$LookForTag"
      if [ $? = 0 ]; then
      echo `killall tail`
      date
      fi
done

echo "'numastat -m':"

numastat -m

echo ""

echo "'numastat -cm | egrep 'Node|Huge'':"

numastat -cm | egrep 'Node|Huge'

echo ""
echo "/sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)"
echo "/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages=$(cat /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages)"
echo "/sys/kernel/mm/transparent_hugepage/enabled=$(cat /sys/kernel/mm/transparent_hugepage/enabled)"
echo "/sys/kernel/mm/transparent_hugepage/defrag=$(cat /sys/kernel/mm/transparent_hugepage/defrag)"
echo "/proc/meminfo huge=$(grep Huge /proc/meminfo)"
echo "/sys/devices/system/node/node*/meminfo | fgrep Huge=$(cat /sys/devices/system/node/node*/meminfo | fgrep Huge)"
echo ""

echo "Launching the data collection"
#echo "***********DOC TYPE IS $DC_TYPE"

#if [ "$DC_TYPE" == "PAT" ]; then
#      echo "Doing PAT data collection"
#      /workloads/PAT/PAT-collecting-data/pat_run.sh
#      echo "Collected PAT data"
#fi

if [ $DC_TYPE == "EDP" ]; then
    sleep 5
    date
    echo " Doing EDP data collectio for 300s"
    emon -M -experimental >$RUNNUM.emon-m.dat
    emon -v -experimental >$RUNNUM.emon-v.dat
    emon -experimental -i ${SEP_LOC_PATH}/config/edp/${EMON_EVENTS_TXT_PREFIX}_events_private.txt >$RUNNUM.emon.dat &
    sleep 300
    killall emon
    sleep 1
    pkill -9 emon

    #sleep 5
    #/workloads/SPECjbb2015/AEPWatch_0.2/bin/AEPWatch 1 120 -f $RUNNUM.AEPWatch.csv 

elif [ $DC_TYPE == "SEP" ]; then
    echo " Do SEP collection now"
    date
    echo "Launching SEP collection" 
    echo "sep -start -d 60 -out $OUTDIR/$4.AVX.sep"
    sep -start -d 60 -out $OUTDIR/$4.AVX.sep
    #sep -start -d $DURATION -out $OUTDIR/$4.sep
    date
    date +'%m%d%H%M%S' > end_of_samples.txt

elif [ $DC_TYPE == "PAT" ]; then
    echo "Doing PAT Data collection"
    /workloads/PAT/PAT-collecting-data/pat_run
    echo "PAT data collection completed"

elif [ $DC_TYPE == "PERF" ]; then
    echo " Do PERF collection now"
    date
    #setting java and perf-map path for flamegraph generation
    sed -i -e "s/JAVA_HOME=\${JAVA_HOME:-.*/JAVA_HOME=\${JAVA_HOME:-\/workloads\/JVM\/$JVM}/g" ../../../FlameGraph/jmaps
    sed -i -e "s/AGENT_HOME=\${AGENT_HOME:-.*/AGENT_HOME=\${AGENT_HOME:-\/workloads\/PerfMapAgents\/$JVM\/perf-map-agent}/g" ../../../FlameGraph/jmaps

    echo "Launching PERF collection"
    echo " perf record -F 99 -a  -g -- sleep 60"
    
    
    perf record -F 99 -a -g -- sleep 60;
    ../../../FlameGraph/jmaps
    
    echo "Creating Flamegraphs"
    perf script | ../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
    ../../../FlameGraph/flamegraph.pl --color=java --hash out.perf-folded > flamegraph.svg
    echo "Perf data collection and Flamegraph creation complete"

elif [ $DC_TYPE == "ALL" ]; then

    echo " Doing EDP data collectio for 60s"
    emon -M >$RUNNUM.emon-m.dat
    emon -v >>$RUNNUM.emon-v.dat
    emon -i /workloads/SPECjbb2015/icx-2s-events.txt >>$RUNNUM.emon.dat &
    sleep 300 
    killall emon
    sleep 1
    killall emon
    sleep 10
    echo "Launching SEP collection" 
    sep -start -d 60 -ec "CPU_CLK_UNHALTED.THREAD","INST_RETIRED.ANY" -out $OUTDIR/$RUNNUM.AVX.sep
    date +'%m%d%H%M%S' > end_of_samples.AVX.txt
    
    #setting java and perf-map path for flamegraph generation
    #sed -i -e "s/JAVA_HOME=\${JAVA_HOME:-.*/JAVA_HOME=\${JAVA_HOME:-\/workloads\/JVM\/$JVM}/g" ../../../FlameGraph/jmaps
    #sed -i -e "s/AGENT_HOME=\${AGENT_HOME:-.*/AGENT_HOME=\${AGENT_HOME:-\/workloads\/PerfMapAgents\/$JVM\/perf-map-agent}/g" ../../../FlameGraph/jmaps

    #echo "Launching PERF collection"
    #echo " perf record -F 99 -a  -g -- sleep 30"


    #perf record -F 99 -a -g -- sleep 30;
    #../../../FlameGraph/jmaps

    #echo "Doing PAT Data collection"
    #/workloads/PAT/PAT-collecting-data/pat_run
    #echo "PAT data collection completed"

    #echo "Creating Flamegraphs"
    #perf script | ../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
    #../../../FlameGraph/flamegraph.pl --color=java --hash out.perf-folded > flamegraph.svg
    #echo "Perf data collection and Flamegraph creation complete"

    #sleep 5
    killall vmstat
else
    echo "invalid selection no collection made Only VMstat data collected"
fi
  
   date
   echo " Data collection complete"




#FP_ARITH_INST_RETIRED.SCALAR_DOUBLE
#FP_ARITH_INST_RETIRED.SCALAR_SINGLE
#FP_ARITH_INST_RETIRED.128B_PACKED_DOUBLE
#FP_ARITH_INST_RETIRED.128B_PACKED_SINGLE
#FP_ARITH_INST_RETIRED.256B_PACKED_DOUBLE
#FP_ARITH_INST_RETIRED.256B_PACKED_SINGLE
#FP_ARITH_INST_RETIRED.512B_PACKED_DOUBLE
#FP_ARITH_INST_RETIRED.512B_PACKED_SINGLE

