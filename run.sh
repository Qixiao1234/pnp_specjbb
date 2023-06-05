#!/bin/bash

###############################################################################
## 
## This script is ment to be called from goMLQ.sh each line being a run of SPECjbb2015 in MultiJVM mode with a specified number of groups 
## Run options are as follows.
#  ./run.sh [HBIR] [kitVersion] [tag] [JDK] [JVMoptions] [DATA collection] [rt_start]"
#  ./run.sh [HBIR_RT] [kitVersion] [tag] [JDK] [JVMoptions] [DATA collection] [rt_start]"
#  ./run.sh [PRESET] [kitVersion] [tag] [JDK] [JVMoptions] [DATA collection] [rt_start] [duration]"
#  ./run.sh [LOADLEVEL] [kitVersion] [tag] [JDK] [JVMoptions] [DATA collection] [rt_start] [duration]"
#  
###############################################################################

function pause(){
   read -p "$*"
}


echo "running with this number of parameters:$#"

# Default Run Type
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
ZONES=$(numactl -H | grep cpus | wc -l)
GC_THREADS=$(( CORES/ZONES ))


 TIER1=$(echo '6.5'*${GC_THREADS} | bc )
MULTIPLICATION_FACTOR=6.5
TIER1=$(echo $GC_THREADS*$MULTIPLICATION_FACTOR | bc)
TIER1=$( printf "%.0f" $TIER1 )
TIER2=$((GC_THREADS*2))
TIER3=$GC_THREADS
GROUPCOUNT=$ZONES


#Calculating the heap size
#MEMORY_PER_CORE=1
#Here g=GB
#MEMORY_UNIT=g
RUN_TYPE=$1
KITVER=$2
ID_TAG=$3
JVM=$4
USR_JVM_OPTS=$5
DATA=$6
RT_CURVE=$7



CPU_MODEL=$(lscpu | grep Model: | awk  '{print $2}')
CPU_TYPE=""
if [ $CPU_MODEL == "106" ] || [ $CPU_MODEL == "108" ]
then
	CPU_CODENAME=icelake
	CPU_TYPE="_server"
fi
if [ $CPU_MODEL == "85" ]
then
	CPU_CODENAME=cascadelake
	CPU_TYPE="_server"
fi
if [ $CPU_MODEL == "134" ]
then
	CPU_CODENAME=snowridge
fi
echo "Found CPU Codename: $CPU_CODENAME"

if [ $1 = "HBIR" ] || [ $1 = "HBIR_RT" ] && [ $# = 11 ]; then
echo  "run type is HBIR or HBIR_RT"
  RT_CURVE=$7
  TIER1=$8
  TIER2=$9
  TIER3=${10}
  GROUPCOUNT=${11}
  sed -e "s/<<HBIR_TYPE>>/$RUN_TYPE/g" -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<RT_CURVE_START>>/$RT_CURVE/g" .HBIR_RT.props > specjbb2015.props


elif [ $1 = "PRESET" ] && [ $# = 12 ]; then
echo  "run type is PRESET"
  PRESET_IR=$7
  DURATION=$(echo "$8*1000" | bc) 
  TIER1=$9
  TIER2=${10}
  TIER3=${11}
  GROUPCOUNT=${12}
  sed -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<PRESET_IR>>/$PRESET_IR/g" -e "s/<<DURATION>>/$DURATION/g" .PRESET.props > specjbb2015.props


elif [ $1 = "LOADLEVEL" ] && [ $# = 12 ]; then
echo  "run type is LOADLEVEL"
  RT_CURVE=$7
  LL_DURATION_MIN=$(echo "$8*1000" | bc) 
  TIER1=$9
  TIER2=${10}
  TIER3=${11}
  LL_DURATION_MAX=$(echo "$8*1000" | bc) 
  GROUPCOUNT=${12}
  sed -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<LL_DUR_MIN>>/$LL_DURATION_MIN/g" -e "s/<<LL_DUR_MAX>>/$LL_DURATION_MAX/g" -e "s/<<RT_CURVE_START>>/$RT_CURVE/g" .LOADLEVELS.props > specjbb2015.props


else
  echo  "run type is invalid"
  echo " invalid number of arguments or invalid Run Type."
  echo " Usage:"
  echo " ./run.sh [HBIR] [kitVersion] [tag] [JDK] [RTSTART] [JVMoptions] [DATA collection]"
  echo " ./run.sh [HBIR_RT] [kitVersion] [tag] [JDK] [RTSTART] [JVMoptions] [DATA collection]"
  echo " ./run.sh [PRESET] [kitVersion] [tag] [JDK] [TXrate] [Duration] [JVMoptions] [DATA collection]"
  echo " ./run.sh [LOADLEVEL] [kitVersion] [tag] [JDK] [RTSTART] [duration] [JVMoptions] [DATA collection]"
  echo "$1, $2, $3, $4, $5,$6, $7, $8, $9, "
  echo " "
  echo " kit version is directory of kit"
  echo " TAG is just a tag or ID to clarify run "
  echo " point to start RT curve"
  echo " JVM options are additional options to be passed to the JVM."
  echo " Number of Nodes is the number of NUMA Nodes to use"
  exit
fi
PFF="-XX:-PrintGCDetails -XX:+PrintFlagsFinal -Xlog:gc+heap+coops=info"

# JAVA_OPTS="-showversion -server -XX:+UseParallelOldGC -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+UseBiasedLocking -XX:+AggressiveOpts -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:SurvivorRatio=18 -XX:MaxTenuringThreshold=15 -XX:InlineSmallCode=10k -verbose:gc -Xms29g -Xmx29g -Xmn28g -XX:ParallelGCThreads=28"
 #OPTS_TI="-server -XX:+UseParallelOldGC -Xmx2g -Xms2g -Xmn1536m"
 #OPTS_CTL="-server -XX:+UseParallelOldGC -Xms2g -Xmx2g -Xmn1536m"

 JAVA_OPTS="-showversion -XX:+UseParallelOldGC -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:SurvivorRatio=28 -XX:MaxTenuringThreshold=15 -XX:InlineSmallCode=10k -verbose:gc -XX:UseAVX=0 -XX:-UseCountedLoopSafepoints -XX:LoopUnrollLimit=20 -XX:MaxGCPauseMillis=500 -XX:AdaptiveSizeMajorGCDecayTimeScale=12 -XX:AdaptiveSizeDecrementScaleFactor=2 -server -XX:TargetSurvivorRatio=95"

PREFETCH="-XX:AllocatePrefetchLines=3 -XX:AllocateInstancePrefetchLines=2 -XX:AllocatePrefetchStepSize=128 -XX:AllocatePrefetchDistance=384"
OPTS_CTL="-server -Xms2g -Xmx2g -Xmn1536m -XX:UseAVX=0 -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+UseParallelOldGC -XX:ParallelGCThreads=2"
OPTS_TI="-server -Xms2g -Xmx2g -Xmn1536m -XX:UseAVX=0 -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+UseParallelOldGC -XX:ParallelGCThreads=2"

 ######Basic JDK8 Run options #######
 #OPTS_CTL="-server -Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelOldGC"
 #OPTS_TI="-server -Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelOldGC"
 #JAVA_OPTS="-showversion -XX:+UseParallelOldGC -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:MaxTenuringThreshold=15 -XX:InlineSmallCode=10k -verbose:gc -server"

 JAVA=/workloads/JVM/$JVM/bin/java

 if [  "$DATA" == "PERF" ]; then
   FRAMEP=" -XX:+PreserveFramePointer"
 fi

  OPTS_BE="$JAVA_OPTS $PREFETCH $USR_JVM_OPTS $PFF $GC_PRINT_OPTS $FRAMEP"


  read RUN_NUM < .run_number
  echo "$RUN_NUM + 1" | bc > .run_number
  echo "RUN NUMBER is :$RUN_NUM"


  TAG=${RUN_NUM}_${RUN_TYPE}_${JVM}_${ID_TAG}_${DATA}_${TIER1}_${TIER2}_${TIER3}_${GROUPCOUNT} 
  ### Create results directory and
  ### copy config to result dir to have full list of settings
  BINARIES_DIR=$(pwd)/$KITVER
  echo "This is the BINARY_DIR $BINARIES_DIR"
  RESULTDIR=$BINARIES_DIR/$TAG
  echo "This is the RESULTDIR $RESULTDIR"
  mv -f specjbb2015.props $BINARIES_DIR/config/
  pushd $KITVER
  pwd
  mkdir $RESULTDIR
  cp -r config $RESULTDIR
  pushd $RESULTDIR

  SUT_INFO=sut.txt
  echo " " > $SUT_INFO
  echo "##############################################################" >> $SUT_INFO
  echo "##########General Options ####################################" >> $SUT_INFO
  echo "##########General Options ####################################"
  echo "ID tag given is:: $TAG" >> $SUT_INFO
  echo "ID tag given is:: $TAG"
  echo "Type of data collection we are doing is:: $DATA" >> $SUT_INFO
  echo "Type of data collection we are doing is:: $DATA"
  echo "Number of NUMA Nodes using:: $GROUPCOUNT" >> $SUT_INFO
  echo "Number of NUMA Nodes using:: $GROUPCOUNT"
  echo "Additional JVM options:: $JVM_OPTS" >> $SUT_INFO
  echo "Additional JVM options:: $JVM_OPTS" 
  echo "All JVM options:: $OPTS_BE" >> $SUT_INFO
  echo "All JVM options:: $OPTS_BE" 
  echo "Controller JVM options:: $OPTS_CTL" >> $SUT_INFO
  echo "Controller JVM options:: $OPTS_CTL" 
  echo "Injector JVM options:: $OPTS_TI" >> $SUT_INFO
  echo "Injector JVM options:: $OPTS_TI" 
  echo "Full path of JAVA used:: $JAVA" >> $SUT_INFO
  echo "Full path of JAVA used:: $JAVA" 


  echo "##################################################################"
  echo "##################################################################" >> $SUT_INFO
  echo "##########SPECjbb2015 Options ####################################" >> $SUT_INFO
  echo "Kit version we are using:: $KITVER" >> $SUT_INFO
  echo "Kit version we are using:: $KITVER"
  echo "Starting RT curve at $RT_CURVE percent" >> $SUT_INFO
  echo "Starting RT curve at $RT_CURVE percent"
  echo "Number of Fork Join Threads to use on Tier1:: $TIER1" >> $SUT_INFO
  echo "Number of Fork Join Threads to use on Tier1:: $TIER1"
  echo "Number of Fork Join Threads to use on Tier2:: $TIER2" >> $SUT_INFO
  echo "Number of Fork Join Threads to use on Tier2:: $TIER2"
  echo "Number of Fork Join Threads to use on Tier3:: $TIER3" >> $SUT_INFO
  echo "Number of Fork Join Threads to use on Tier3:: $TIER3"
  echo "Groups count: $GROUPCOUNT" >> $SUT_INFO
  echo "Groups count: $GROUPCOUNT"
  echo "JVM options for Controller:$OPTS_CTL" >> $SUT_INFO
  echo "JVM options for Controller:$OPTS_CTL"
  echo "JVM options for Injector:$OPTS_TI" >> $SUT_INFO
  echo "JVM options for Injector:$OPTS_TI"
  echo "">>$SUT_INFO
  echo "">>$SUT_INFO 
  echo "************Dump OS related options*********************************">>$SUT_INFO

  echo "Dump sysctl data for logging" 
  sysctl -a >> sysctl-a.log
  ulimit -a >> ulimit-a.log


  read TMP < /proc/sys/vm/dirty_expire_centisecs
  echo "/proc/sys/vm/dirty_expire_centisecs="$TMP >>$SUT_INFO
  read TMP < /proc/sys/vm/dirty_writeback_centisecs
  echo "/proc/sys/vm/dirty_writeback_centisecs="$TMP >>$SUT_INFO
  read TMP < /proc/sys/kernel/sched_rt_runtime_us
  echo "/proc/sys/kernel/sched_rt_runtime_us="$TMP >>$SUT_INFO
  read TMP < /proc/sys/kernel/sched_migration_cost_ns
  echo "/proc/sys/kernel/sched_migration_cost_ns="$TMP >>$SUT_INFO
  read TMP < /proc/sys/kernel/sched_nr_migrate
  echo "/proc/sys/kernel/sched_nr_migrate="$TMP >>$SUT_INFO
  read TMP < /proc/sys/kernel/sched_cfs_bandwidth_slice_us
  echo "/proc/sys/kernel/sched_cfs_bandwidth_slice_us="$TMP >>$SUT_INFO
  read TMP < /proc/sys/kernel/sched_child_runs_first
  echo "/proc/sys/kernel/sched_child_runs_first="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_latency_ns
  echo "/proc/sys/kernel/sched_latency_ns="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_min_granularity_ns
  echo "/proc/sys/kernel/sched_min_granularity_ns="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_rr_timeslice_ms
  echo "/proc/sys/kernel/sched_rr_timeslice_ms="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_rt_period_us
  echo "/proc/sys/kernel/sched_rt_period_us="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_schedstats
  echo "/proc/sys/kernel/sched_schedstats="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_tunable_scaling
  echo "/proc/sys/kernel/sched_tunable_scaling="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/sched_wakeup_granularity_ns
  echo "/proc/sys/kernel/sched_wakeup_granularity_ns="$TMP >> $SUT_INFO
  read TMP < /proc/sys/vm/dirty_ratio
  echo "/proc/sys/vm/dirty_ratio="$TMP >> $SUT_INFO
  read TMP < /proc/sys/vm/dirty_background_ratio
  echo "/proc/sys/vm/dirty_background_ratio="$TMP >> $SUT_INFO
  read TMP < /proc/sys/vm/swappiness
  echo "/proc/sys/vm/swappiness="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/numa_balancing
  echo "/proc/sys/kernel/numa_balancing="$TMP >> $SUT_INFO
  read TMP < /sys/kernel/mm/transparent_hugepage/defrag
  echo "/sys/kernel/mm/transparent_hugepage/defrag="$TMP >> $SUT_INFO
  read TMP < /sys/kernel/mm/transparent_hugepage/enabled
  echo "/sys/kernel/mm/transparent_hugepage/enabled="$TMP >> $SUT_INFO
  TMP=""
  read TMP < /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
  echo "/sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages="$TMP >> $SUT_INFO
  TMP=""
  read TMP < /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
  echo "/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/shmmax
  echo "/proc/sys/kernel/shmmax="$TMP >> $SUT_INFO
  read TMP < /proc/sys/kernel/shmall
  echo "/proc/sys/kernel/shmall="$TMP >> $SUT_INFO

  echo "************system config details ****************************">>$SUT_INFO
  
  uname -a >> $SUT_INFO; numactl --hardware >> $SUT_INFO; 
  read TMP < /proc/cmdline
  echo "Kernel boot command: "$TMP >> $SUT_INFO

  echo "************copy shell scripts to output Directory****************************">>$SUT_INFO
  cp ../../*.sh .

   # Log system info to the SUT_INFO
  

  echo "************Latencies*********************************">>$SUT_INFO
  #echo "***running svr_info*********************************"
  #/workloads/SPECjbb2015/svrinfo-master/svr_info.sh


   #SUT Product descriptions
   sed -i -e "s/<<JVM>>/$JVM/g" config/template-M.raw
   sed -i -e "s/<<Injector JVM OPTIONS>>/$OPTS_TI/g" config/template-M.raw
   sed -i -e "s/<<BACKEND JVM OPTIONS>>/$OPTS_BE/g" config/template-M.raw
   sed -i -e "s/<<CONTROLLER JVM OPTIONS>>/$OPTS_CTL/g" config/template-M.raw
   sed -i -e "s/<<GroupCount>>/$GROUPCOUNT/g" config/template-M.raw

   now="$(date)"
   sed -i -e "s/<<DATE>>/$now/g" config/template-M.raw

   #../../PopulateRunDetails.pl

  
  #echo "***running mlc for Latencies*********************************" >Latencies.log
  echo 4000 > /proc/sys/vm/nr_hugepages
  /workloads/SPECjbb2015/mlc >> Latencies.log
  echo "***running mlc loaded Latencies*********************************" >>Latencies.log
  /workloads/SPECjbb2015/mlc --loaded_latency -W2 >>Latencies.log
  echo 0 > /proc/sys/vm/nr_hugepages

  echo "">>$SUT_INFO
  echo "">>$SUT_INFO
  echo "************Memory Config*********************************">>$SUT_INFO
         dmidecode | grep MHz >>$SUT_INFO
         dmidecode | grep -i range >>$SUT_INFO
  echo "**********************************************************"


  if [ $DATA != "NONE" ] || [ "$DATA" == "JFR" ]; then
     echo "Launching Data collection"
     EMON_EVENTS_TXT_PREFIX="$CPU_CODENAME$CPU_TYPE"
     ../../data.sh $DATA $RESULTDIR $RUN_NUM $RUN_TYPE $JVM $EMON_EVENTS_TXT_PREFIX > datacollection.log &
  fi


  if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
      echo "Doing SEP data collection"
      echo "Copying files for SEP Post Processing"
      cp /workloads/JVM/$JVM/lib/server/libjvm.so .
      cp /boot/System.map-3.10.0-862.el7.x86_64 .
      cp /boot/System.map-3.10.0-957.el7.x86_64 .
      cp /workloads/SPECjbb2015/fs2xl.exe .   
      SEP="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$BE_NAME.jsym"
  fi

 echo "Launching SPECjbb2015 in MultiJVM mode..."
  
 OUT=controller.out
 LOG=controller.log
 TI_JVM_COUNT=1

     
 vmstat -nt 1 > $RUN_NUM.vmstat.log &
 
 # start Controller on this host
 echo "Start Controller JVM"
 echo "$JAVA $OPTS_C -jar ../specjbb2015.jar -m MULTICONTROLLER"
 if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
    #echo "Doing SEP data collection"
     SEPC="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=Controller.jsym"
 fi
 if [ "$DATA" == "JFR" ]; then
    SEPC="-XX:+UnlockCommercialFeatures -XX:+FlightRecorder -XX:StartFlightRecording=delay=300s,duration=180s,filename=Controller.jfr"
 fi 
   C_NUMA="numactl --interleave=all"
   $JAVA $OPTS_CTL $SEPC -Xlog:gc*:file=Ctrlr.GC.log -jar ../specjbb2015.jar -m MULTICONTROLLER 2>$LOG > $OUT &
   #$C_NUMA $JAVA $OPTS_CTL $SEPC -jar ../specjbb2015.jar -m MULTICONTROLLER 2>$LOG > $OUT &
   echo "$C_NUMA $JAVA $OPTS_CTL -jar ../specjbb2015.jar -m MULTICONTROLLER" >> $SUT_INFO

 sleep 5

 CTRL_PID=$!
 echo "Controller PID = $CTRL_PID"

 # 5 sec should be enough to initialize Controller
 # set bigger delay if needed
 echo "Wait while Controller starting ..."
 sleep 5

 echo "group count is $GROUPCOUNT"

 for ((gnum=1; $gnum<$GROUPCOUNT+1; gnum=$gnum+1)); do
       GROUPID=Group$gnum
       echo -e "\nStarting JVMs from $GROUPID:"
       node=`expr "$gnum" - 1`
       NewNode=$(($node%8));
       echo "******$node ******* $NewNode****"

       NUMAON="numactl --cpunodebind=$NewNode --localalloc"

       echo "TI_JVM_COUNT is $TI_JVM_COUNT"
       for ((jnum=1; $jnum<$TI_JVM_COUNT+1; jnum=$jnum+1)); do

           JVMID=JVM$jnum
           TI_NAME=$GROUPID.TxInjector.$JVMID
           if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
               #echo "Doing SEP data collection"
               SEPTx="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$TI_NAME.jsym"
           fi
           if [ "$DATA" == "JFR" ]; then
               SEPTx="-XX:+UnlockCommercialFeatures -XX:+FlightRecorder -XX:StartFlightRecording=delay=120s,duration=300s,filename=$TI_NAME.jfr"
           fi 
           # start TxInjector on this host
           echo "$NUMAON $JAVA $OPTS_TI $SEPTx -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID" >> $SUT_INFO
           

	  $NUMAON $JAVA $OPTS_TI $SEPTx -Xlog:gc*:file=$TI_NAME.GC.log -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
	  # $NUMAON $JAVA $OPTS_TI $SEPTx -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
       done

       for ((jnum=1+$TI_JVM_COUNT; $jnum<$TI_JVM_COUNT+2; jnum=$jnum+1)); do

          JVMID=JVM$jnum
          BE_NAME=$GROUPID.Backend.$JVMID

          if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
               #echo "Doing SEP data collection"
               SEPBE="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$BE_NAME.jsym"
          fi
          if [ "$DATA" == "JFR" ]; then
               #echo "Collecting JFR"
               SEPBE="-XX:+UnlockCommercialFeatures -XX:+FlightRecorder -XX:StartFlightRecording=delay=120s,duration=300s,filename=$BE_NAME.jfr"
          fi

          # start Backend on local SUT host
          echo "$NUMAON $JAVA $SEPBE $PFF $OPTS_BE -Xloggc:$BE_NAME.GC.log -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID" >>$SUT_INFO
	  $NUMAON $JAVA $SEPBE $PFF $OPTS_BE -Xlog:gc*:file=$BE_NAME.GC.log -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
	  #$NUMAON $JAVA $SEPBE $OPTS_BE -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
       done
  done

  echo "Wait while specjbb2015 is running ..."
  echo "Press Ctrl-break to stop the run"
  wait $CTRL_PID

  echo "Controller stopped"
  echo "Kill all related proceses"
  sleep 15

  cat /proc/swaps >> $SUT_INFO;
  cat /proc/meminfo >> $SUT_INFO; 
  cat /proc/cpuinfo >> $SUT_INFO;
 
  killall data.sh 
  killall tail 
  

  $JAVA -Xms4g -Xmx4g -jar ../specjbb2015.jar -m REPORTER -s specjbb2015*.data.gz
  killall edp 
  killall emon 
  sleep 15
  if [ "$DATA" = "EDP"  ] || [ "$DATA" = "ALL" ]
  then   
	source /workloads/SEP/sep_vars.sh
	echo " Generating edp_config.txt for EDP Processing .."
	if [ -z "$PRESET_IR" ]
	then 
		GMAXIR=$(grep critical controller.out |  cut -d " " -f 14)
		CHARLEN=${#GMAXIR}
		MAXIR=$(echo $GMAXIR | cut -c 1-$(expr $CHARLEN - 1))
		THROUGHPUT=$(awk "BEGIN {print $MAXIR *.95}")
	else 
		THROUGHPUT=$PRESET_IR
	fi	
	echo "Found Throughput: $THROUGHPUT"
	echo "Using CPU Codename: $CPU_CODENAME"
	EDP_CONFIG="RUBY_PATH=$(which ruby)\nPARALLELISM=24\nEMON_DATA="${RESULTDIR}/$RUN_NUM.emon.dat"\nOUTPUT="${RESULTDIR}/$RUN_NUM.summary.xlsx"\nMETRICS="${SEP_LOC_PATH}/config/edp/${CPU_CODENAME}_server_2s_private.xml"\nBEGIN=1\nEND=100000\nVIEW=--socket-view\nTPS=--tps $THROUGHPUT\nTIMESTAMP_IN_CHART='--timestamp-in-chart'"
	echo "EDP Config: \n$EDP_CONFIG"
	echo -e "${EDP_CONFIG}" > edp_config.txt
	emon -process-edp ./edp_config.txt
  fi
  killall edp 
  killall emon 
  killall java 
  killall vmstat
  cp result/specjbb2015*/report*/*.html .
  #uname -a >> $SUT_INFO; numactl --hardware >> $SUT_INFO; cat /proc/meminfo >> $SUT_INFO; cat /proc/cpuinfo >> $SUT_INFO;
  
  sed "s/^[ \t]*//" -i $RUN_NUM.vmstat.log

exit 0
