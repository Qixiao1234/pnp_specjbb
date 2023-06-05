#!/bin/bash

###############################################################################
##
## This script is ment to be called from goMLQ.sh each line being a run of SPECjbb2015 in MultiJVM mode with a specified number of groups
## Run options are as follows.
#  ./run.sh [HBIR] [kitVersion] [tag] [JDK] [MEMORY_PER_CORE] [RTSTART] [JVMoptions] [DATA collection] "
#  ./run.sh [HBIR_RT] [kitVersion] [tag] [JDK]  [MEMORY_PER_CORE] [RTSTART] [JVMoptions] [DATA collection]"
#  ./run.sh [PRESET] [kitVersion] [tag] [JDK] [MEMORY_PER_CORE] [TXrate] [Duration] [JVMoptions] [DATA collection] "
#  ./run.sh [LOADLEVEL] [kitVersion] [tag] [JDK] [MEMORY_PER_CORE] [RTSTART] [duration] [JVMoptions] [DATA collection] "
#
###############################################################################

function pause(){
   read -p "$*"
}

jar_path=$(pwd)
echo "running with this number of parameters:$#"

echo "emon start"


# Default Run Type
CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
ZONES=$(numactl -H | grep cpus | wc -l)
GC_THREADS=$(( CORES/ZONES ))

# TIER1=$(echo '6.5'*${GC_THREADS} | bc )
#TIER1=182
MULTIPLICATION_FACTOR=7
TIER1=$(echo $GC_THREADS*$MULTIPLICATION_FACTOR | bc)
TIER1=$( printf "%.0f" $TIER1 )
TIER2=$((GC_THREADS*2/10))
TIER3=$((GC_THREADS*1))
TIER1=168
TIER2=6
TIER3=29
GROUPCOUNT=$ZONES

#Calculating the heap size
MEMORY_PER_CORE=1
#Here g=GB
MEMORY_UNIT=g
TOTAL_HEAP_MEMORY=$(echo $GC_THREADS*$MEMORY_PER_CORE | bc)
TOTAL_HEAP_MEMORY=$( printf "%.0f" $TOTAL_HEAP_MEMORY )
HEAP_SIZE=$TOTAL_HEAP_MEMORY$MEMORY_UNIT
echo "HEAP SIZE IS $HEAP_SIZE"

NURSERY_MEMORY=$(echo $TOTAL_HEAP_MEMORY - 2 | bc)
NURSERY_SIZE=$NURSERY_MEMORY$MEMORY_UNIT
echo "NURSERY_SIZE is $NURSERY_SIZE"

RUN_TYPE=$1
KITVER=$2
ID_TAG=$3
JVM=$4
USR_JVM_OPTS=$5
DATA=$6


if [ $1 = "HBIR" ] || [ $1 = "HBIR_RT" ] && [ $# = 8 ]; then
echo  "run type is HBIR or HBIR_RT"
  RT_CURVE=$7
  RT_CURVE_STEP=$8
  sed -e "s/<<HBIR_TYPE>>/$RUN_TYPE/g" -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<RT_CURVE_START>>/$RT_CURVE/g" -e "s/<<RT_CURVE_STEP>>/$RT_CURVE_STEP/g" .HBIR_RT.props > specjbb2015.props


elif [ $1 = "PRESET" ] && [ $# = 8 ]; then
echo  "run type is PRESET"
  PRESET_IR=$7
  DURATION=$(echo "$8*1000" | bc)
  sed -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<PRESET_IR>>/$PRESET_IR/g" -e "s/<<DURATION>>/$DURATION/g" .PRESET.props > specjbb2015.props


elif [ $1 = "LOADLEVEL" ] && [ $# = 9 ]; then
echo  "run type is LOADLEVEL"
  RT_CURVE=$7
  LL_DURATION_MIN=$(echo "$8*1000" | bc)
  LL_DURATION_MAX=$(echo "$8*1000" | bc)
  RT_CURVE_STEP=$9
  sed -e "s/<<T1>>/$TIER1/g" -e "s/<<T2>>/$TIER2/g" -e "s/<<T3>>/$TIER3/g" -e "s/<<GROUP_COUNT>>/$GROUPCOUNT/g" -e "s/<<LL_DUR_MIN>>/$LL_DURATION_MIN/g" -e "s/<<LL_DUR_MAX>>/$LL_DURATION_MAX/g" -e "s/<<RT_CURVE_START>>/$RT_CURVE/g" -e "s/<<RT_CURVE_STEP>>/$RT_CURVE_STEP/g" .LOADLEVELS.props > specjbb2015.props


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
# JAVA_OPTS="-showversion -XX:ParallelGCThreads=$GC_THREADS -Xms$HEAP_SIZE -Xmx$HEAP_SIZE -Xmn$NURSERY_SIZE -XX:+UseParallelOldGC -XX:+UseLargePages -XX:LargePageSizeInBytes=2m -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:SurvivorRatio=28 -XX:MaxTenuringThreshold=15 -XX:InlineSmallCode=10k -verbose:gc"
JAVA_OPTS="-showversion -XX:ParallelGCThreads=$GC_THREADS -Xms$HEAP_SIZE -Xmx$HEAP_SIZE -Xmn$NURSERY_SIZE -XX:UseAVX=0 -XX:+UseParallelGC -XX:+UseLargePages -XX:+AlwaysPreTouch -XX:-UseAdaptiveSizePolicy -XX:SurvivorRatio=28 -XX:MaxTenuringThreshold=15 -XX:InlineSmallCode=10k -verbose:gc -XX:-UseCountedLoopSafepoints -XX:LoopUnrollLimit=20 -XX:MaxGCPauseMillis=500 -XX:AdaptiveSizeMajorGCDecayTimeScale=12 -XX:AdaptiveSizeDecrementScaleFactor=2 -XX:TargetSurvivorRatio=99 -XX:LargePageSizeInBytes=1G -XX:AllocatePrefetchLines=3 -XX:AllocateInstancePrefetchLines=2 -XX:AllocatePrefetchStepSize=128 -XX:AllocatePrefetchDistance=384"

  GC_PRINT_OPTS=""
  OPTS_TI="-server -Xms2g -Xmx2g -Xmn1536m -XX:UseAVX=0 -XX:+UseLargePages -XX:LargePageSizeInBytes=1G -XX:+UseParallelGC -XX:ParallelGCThreads=2"
  OPTS_CTL="-server -Xms2g -Xmx2g -Xmn1536m -XX:UseAVX=0 -XX:+UseLargePages -XX:LargePageSizeInBytes=1G -XX:+UseParallelGC -XX:ParallelGCThreads=2 $SPEC_OPTS"
  #JAVA=/u01/j.chen/dockerbuild-jbb2015/SPECjbb2015-master/jre/bin/java
  #JAVA=/u01/j.chen/dockerbuild-jbb2015/jre/bin/java
  #JAVA=/root/SPECjbb2015-master/jdk-11.0.2/bin/java
  # need to modify
  JAVA=/usr/lib/jvm/java-11-openjdk-11*/bin/java
  #/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-4.el8_5.x86_64/s
  #JAVA=$JAVA_HOME/bin/java

  OPTS_BE="$JAVA_OPTS $USR_JVM_OPTS $GC_PRINT_OPTS"


  read RUN_NUM < .run_number
  echo "$RUN_NUM + 1" | bc > .run_number
  echo "RUN NUMBER is :$RUN_NUM"

  timestamp=$(date '+%y-%m-%d_%H%M%S')
  TAG=${RUN_NUM}_${RUN_TYPE}_${KITVER}_${JVM}_${ID_TAG}_${DATA}_${timestamp}
  ### Create results directory and
  ### copy config to result dir to have full list of settings
  BINARIES_DIR=$(pwd)/$KITVER
  echo "This is the BINARY_DIR $BINARIES_DIR"
  RESULTDIR=$BINARIES_DIR/$TAG
  echo "This is the RESULTDIR $RESULTDIR"
  cp -f specjbb2015.props $BINARIES_DIR/config/
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
  echo "************Latencies*********************************">>$SUT_INFO



   # Log system info to the SUT_INFO

  pwd
  #echo "************Latencies*********************************">>$SUT_INFO
  echo "***running svr_info*********************************"
  #/workloads/SPECjbb2015/svrinfo-master/svr_info.sh

        # Result html generator
        # SUT Product descriptions into template-M.raw
        sed -i -e "s/<<JVM>>/$JVM/g" config/template-M.raw

        sed -i -e "s/<<Injector JVM OPTIONS>>/$OPTS_TI/g" config/template-M.raw
        sed -i -e "s/<<BACKEND JVM OPTIONS>>/$OPTS_BE/g" config/template-M.raw
        sed -i -e "s/<<CONTROLLER JVM OPTIONS>>/$OPTS_CTL/g" config/template-M.raw

        sed -i -e "s/<<GroupCount>>/$GROUPCOUNT/g" config/template-M.raw

        now="$(date)"
        sed -i -e "s/<<DATE>>/$now/g" config/template-M.raw

#       ../../PopulateRunDetails.pl  # populate server details into template-M.raw

  #echo "***running mlc for Latencies*********************************"
  #/workloads/SPECjbb2015/mlc >>$SUT_INFO
  #echo "***running mlc loaded Latencies*********************************"
  #/workloads/SPECjbb2015/mlc --loaded_latency -W2 >>$SUT_INFO
  #echo "">>$SUT_INFO
  #echo "">>$SUT_INFO
  #echo "************Memory Config*********************************">>$SUT_INFO
  #       dmidecode | grep MHz >>$SUT_INFO
  #       dmidecode | grep -i range >>$SUT_INFO
  #echo "**********************************************************"


  pwd
#  if [ $DATA != "NONE" ]; then
#     echo "Launching Data collection"
#     #../../../data.sh $DATA $RESULTDIR $RUN_NUM $RUN_TYPE > datacollection.log &
#	 /root/SPECjbb2015-master/data.sh $DATA $RESULTDIR $RUN_NUM $RUN_TYPE > datacollection.log &
#  fi


#  if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
#      echo "Doing SEP data collection"
#      echo "Copying files for SEP Post Processing"
#      cp /workloads/JVM/$JVM/lib/server/libjvm.so .
#      cp /boot/System.map-3.10.0-862.el7.x86_64 .
#      cp /boot/System.map-3.10.0-957.el7.x86_64 .
#      cp /workloads/SPECjbb2015/fs2xl.exe .
#      SEP="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$BE_NAME.jsym"
#  fi

 echo "Launching SPECjbb2015 in MultiJVM mode..."

 OUT=controller.out
 LOG=controller.log
 TI_JVM_COUNT=1

 uname -a >> $SUT_INFO;
# numactl --hardware >> $SUT_INFO;

# vmstat -nt 1 > $RUN_NUM.vmstat.log &

 # start Controller on this host
 echo "Start Controller JVM"
 echo "$JAVA $OPTS_C -jar ../specjbb2015.jar -m MULTICONTROLLER"
 #if [ "$DATA" == "SEP" ]; then
 if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
     echo "Doing SEP data collection"
     SEPC="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=Controller.jsym"
 fi
   pwd
   #$JAVA $OPTS_CTL $SEPC -Xlog:gc*:file=Ctrlr.GC.log -jar ../specjbb2015.jar -m MULTICONTROLLER 2>$LOG > $OUT &
   #$JAVA $OPTS_CTL $SEPC -jar ../specjbb2015.jar -m MULTICONTROLLER 2>$LOG > $OUT &
   $JAVA $OPTS_CTL $SEPC -jar $jar_path/specjbb2015.jar -m MULTICONTROLLER 2>$LOG > $OUT &
   echo "$JAVA $OPTS_CTL -jar ../specjbb2015.jar -m MULTICONTROLLER" >> $SUT_INFO

 sleep 5
 ##$JAVA -Dspecjbb.controller.host=localhost -jar specjbb2015.jar -m TIMESERVER

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
       NewNode=$(($node%16));
       echo "******$node ******* $NewNode****"

       NUMAON="numactl --cpunodebind=$NewNode --localalloc"
       #NUMAON="numactl --cpunodebind=$NewNode --membind=1"

       echo "TI_JVM_COUNT is $TI_JVM_COUNT"
       for ((jnum=1; $jnum<$TI_JVM_COUNT+1; jnum=$jnum+1)); do

           JVMID=JVM$jnum
           TI_NAME=$GROUPID.TxInjector.$JVMID
           if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
           #if [ "$DATA" == "SEP" ]; then
               echo "Doing SEP data collection"
               SEPTx="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$TI_NAME.jsym"
           fi

           # start TxInjector on this host
#           echo "$NUMAON $JAVA $OPTS_TI -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID" >> $SUT_INFO

           #$NUMAON $JAVA $OPTS_TI $SEPTx -Xlog:gc*:file=$TI_NAME.GC.log -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
           #$NUMAON $JAVA $OPTS_TI $SEPTx -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
#		   $NUMAON $JAVA $OPTS_TI $SEPTx -jar /root/SPECjbb2015-master/jbb103/specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
		   $NUMAON $JAVA $OPTS_TI $SEPTx -jar $jar_path/specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID > $TI_NAME.log 2>&1 &
       done

       for ((jnum=1+$TI_JVM_COUNT; $jnum<$TI_JVM_COUNT+2; jnum=$jnum+1)); do

          JVMID=JVM$jnum
          BE_NAME=$GROUPID.Backend.$JVMID

          if [ "$DATA" == "ALL" ] || [ "$DATA" == "SEP" ]; then
          #if [ "$DATA" == "SEP" ]; then
               echo "Doing SEP data collection"
               SEPBE="-agentpath:/workloads/JVM/libjvmtisym/libjvmtisym.so=ofile=$BE_NAME.jsym"
          fi

          # start Backend on local SUT host
          #echo "$NUMAON $JAVA $OPTS_BE -Xloggc:$BE_NAME.GC.log -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID" >>$SUT_INFO
          #$NUMAON $JAVA $SEPBE $OPTS_BE -Xlog:gc*:file=$BE_NAME.GC.log -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
#         echo "$NUMAON $JAVA $OPTS_BE -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID" >>$SUT_INFO
          #$NUMAON $JAVA $SEPBE $OPTS_BE -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
#		   $NUMAON $JAVA $SEPBE $OPTS_BE -jar /root/SPECjbb2015-master/jbb103/specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
		   $NUMAON $JAVA $SEPBE $OPTS_BE -jar $jar_path/specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID > $BE_NAME.log 2>&1 &
       done
  done

  echo "Wait while specjbb2015 is running ..."
  echo "Press Ctrl-break to stop the run"
  wait $CTRL_PID

  echo "Controller stopped"
  echo "Kill all related proceses"
  sleep 15

#  cat /proc/swaps >> $SUT_INFO;
#  cat /proc/meminfo >> $SUT_INFO; cat /proc/cpuinfo >> $SUT_INFO;

#  killall data.sh
  killall tail


  #$JAVA -Xms4g -Xmx4g -jar ../specjbb2015.jar -m REPORTER -s specjbb2015*.data.gz -l 3
  $JAVA -Xms4g -Xmx4g -jar $jar_path/specjbb2015.jar -m REPORTER -s specjbb2015*.data.gz -l 3

  #../KillDataCollection.sh
  sleep 15
  killall java
#  killall vmstat
  cp result/specjbb2015*/report*/*.html .
  uname -a >> $SUT_INFO;
#  numactl --hardware >> $SUT_INFO; cat /proc/meminfo >> $SUT_INFO; cat /proc/cpuinfo >> $SUT_INFO;

#  sed "s/^[ \t]*//" -i $RUN_NUM.vmstat.log

   #while IFS=: read -r c1 c2; do
   # [[ $c1 == Node ]] && var=$c1
   # [[ $c1 == INFO ]] && echo "$var$c2"
   #done < SAMPLE_DIVISOR

  cp -r $RESULTDIR /result

exit 0
