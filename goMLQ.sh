#!/bin/bash
#########################################################################################################
#
#  ./run.sh [TYPE] [kitVers] [tag] [Fk-JnT] [JDKVersion] [RTSTART] [JVMopt] [NumberofNodes] [CollectionType] [T1Fk-JnT] [T2Fk-JnT] [T3Fk-JnT]
#
#########################################################################################################

function pause(){
   read -p "$*"
}
#./run.sh HBIR_RT jbb102 test jdk1.12-OJ.ea19 "-server" NONE 0
#./run.sh LOADLEVEL jbb102 test jdk1.12-OJ.ea19 "-server" NONE 600 
#./run.sh PRESET jbb102 test jdk1.12-OJ.ea19 "-server" NONE 170000 600
#./run.sh PRESET jbb102 ALL_160K jdk1.11-b2 "-server -Xms29g -Xmx29g -Xmn27g" PERF 160000 800




ulimit -n 1024000

sysctl net.core.wmem_max=12582912
sysctl net.core.rmem_max=12582912
sysctl net.ipv4.tcp_rmem='10240 87380 12582912'
sysctl net.ipv4.tcp_wmem='10240 87380 12582912'
sysctl net.core.netdev_max_backlog=655560
sysctl net.core.somaxconn=32768
sysctl net.ipv4.tcp_no_metrics_save=1
systemctl stop systemd-update-utmp-runlevel.service

# New BKM Options
echo 10000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
echo 0 > /proc/sys/kernel/sched_child_runs_first
echo 16000000 > /proc/sys/kernel/sched_latency_ns
echo 1000 > /proc/sys/kernel/sched_migration_cost_ns
echo 28000000 > /proc/sys/kernel/sched_min_granularity_ns
echo 9 > /proc/sys/kernel/sched_nr_migrate
echo 100 > /proc/sys/kernel/sched_rr_timeslice_ms
echo 1000000 > /proc/sys/kernel/sched_rt_period_us
echo 990000 > /proc/sys/kernel/sched_rt_runtime_us
echo 0 > /proc/sys/kernel/sched_schedstats
echo 1 > /proc/sys/kernel/sched_tunable_scaling
echo 50000000 > /proc/sys/kernel/sched_wakeup_granularity_ns
echo 3000 > /proc/sys/vm/dirty_expire_centisecs
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
echo 40 > /proc/sys/vm/dirty_ratio
echo 10 > /proc/sys/vm/dirty_background_ratio
echo 10 > /proc/sys/vm/swappiness
echo 0 > /proc/sys/kernel/numa_balancing

echo always > /sys/kernel/mm/transparent_hugepage/defrag
echo always > /sys/kernel/mm/transparent_hugepage/enabled
#tuned-adm profile=throughput-performance
#cpupower -c all frequency-set -g performance
emon --write-msr 1a4=4
ulimit -v 800000000
ulimit -m 800000000
ulimit -l 800000000
ulimit -n 1024000
UserTasksMax=970000
DefaultTasksMax=970000

#echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
#echo 256 >  /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
#echo  "/sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages: $(cat /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages)"

./run.sh LOADLEVEL jbb103 Limited_Perf jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh PRESET jbb103 Base jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 155000 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 Fixed_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh LOADLEVEL jbb103 Base_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Base_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh LOADLEVEL jbb103 Fixed_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Fixed_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
do
            [ -f $CPUFREQ ] || continue
            sudo echo -n performance > $CPUFREQ

./run.sh LOADLEVEL jbb103 Base_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Base_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Base_16D39 jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

exit

./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 SNC_TEST jdk1.13-b32 "-Xms29g -Xmx27g -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 24 4
exit

./run.sh LOADLEVEL jbb103 SNC_BUG jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 168 6 12 4
exit

./run.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.14-b36 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 160 6 24 2
exit
./run.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 320 12 48 2
./run.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 320 12 48 2
./runJDK8.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.8-u20 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 320 12 48 2
./runJDK8.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.8-u20 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 320 12 48 2
./runJDK8.sh LOADLEVEL jbb103 Paula_NoLLC_SNM_Dis jdk1.8-u20 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 320 12 48 2
exit



echo 5000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_5m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_5m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

echo 10000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_10m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_10m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

echo 15000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_15m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_15m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

echo 20000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_20m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_20m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

echo 25000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_25m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_25m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

echo 30000000 > /proc/sys/kernel/sched_latency_ns
./run.sh LOADLEVEL jbb103 Sched_Lat_30m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Sched_Lat_30m jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit


./run.sh LOADLEVEL jbb103 NoSNC_8Gr jdk1.13-b32 "-Xms30g -Xmx30g -Xmn29g -XX:ParallelGCThreads=12" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 NoSNC_8Gr jdk1.13-b32 "-Xms30g -Xmx30g -Xmn29g -XX:ParallelGCThreads=12" EDP 0 600 168 6 29 8

exit

./run.sh LOADLEVEL jbb103 5_HMLS_Pre_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 5_HMLS_Pre_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 5_HMLS_Pre_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit


emon --write-msr 0xe2=0x8403
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.11-b2 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.11-b2 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.12-OJ.ea24 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.12-OJ.ea24 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 JDK_Scaling jdk1.14-b36 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

./run.sh PRESET jbb103 DemotionDis_10K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 10000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_20K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 20000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_30K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 30000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_40K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 40000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_50K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 50000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_60K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 60000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_70K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 70000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_80K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 80000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_90K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 90000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_100K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 100000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_110K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 110000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_120K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 120000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_130K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 130000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_140K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 140000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_150K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 150000 400 168 6 29 4

emon --write-msr 0xe2=0x14008403
./run.sh LOADLEVEL jbb103 DemotionEna jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DemotionEna jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

./run.sh PRESET jbb103 DemotionEna_10K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 10000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_20K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 20000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_30K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 30000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_40K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 40000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_50K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 50000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_60K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 60000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_70K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 70000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_80K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 80000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_90K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 90000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_100K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 100000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_110K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 110000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_120K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 120000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_130K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 130000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_140K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 140000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionEna_150K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 150000 400 168 6 29 4
exit

exit

./run.sh PRESET jbb103 DemotionDis_10K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 10000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_20K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 20000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_30K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 30000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_40K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 40000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_50K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 50000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_60K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 60000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_70K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 70000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_80K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 80000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_90K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 90000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_100K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 100000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_110K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 110000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_120K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 120000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_130K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 130000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_140K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 140000 400 168 6 29 4
./run.sh PRESET jbb103 DemotionDis_150K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 150000 400 168 6 29 4



exit

./run.sh LOADLEVEL jbb103 NoSNC_2Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 336 12 58 2
./run.sh LOADLEVEL jbb103 NoSNC_2Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 336 12 58 2
./run.sh LOADLEVEL jbb103 NoSNC_2Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 168 6 29 2
./run.sh LOADLEVEL jbb103 NoSNC_2Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 168 6 29 2
./run.sh LOADLEVEL jbb103 NoSNC_2Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 168 6 29 2

exit
./run.sh PRESET jbb103 DemotionDis_25K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 25000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionDis_50K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 50000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionDis_75K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 75000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionDis_100K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 100000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionDis_125K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 125000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionDis_150K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 150000 600 168 6 29 2

emon --write-msr 0xe2=0x14008403  Demotion enabled
./run.sh LOADLEVEL jbb103 DemotionEna jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 168 6 29 2
./run.sh LOADLEVEL jbb103 DemotionEna jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 0 600 168 6 29 2

./run.sh PRESET jbb103 DemotionEna_25K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 25000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionEna_50K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 50000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionEna_75K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 75000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionEna_100K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 100000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionEna_125K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 125000 600 168 6 29 2
./run.sh PRESET jbb103 DemotionEna_150K jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=48" EDP 150000 600 168 6 29 2

exit


echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 240000 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

./run.sh LOADLEVEL jbb103 2M_LP jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=2m" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2M_LP jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=2m" EDP 0 600 168 6 29 4

echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
echo 256 >  /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

./run.sh LOADLEVEL jbb103 1GB_LP jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=1g" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 1GB_LP jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=1g" EDP 0 600 168 6 29 4

echo always > /sys/kernel/mm/transparent_hugepage/enabled
echo 0 >  /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
echo 240000 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

./run.sh LOADLEVEL jbb103 2M_LP_TH_always jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=2m" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2M_LP_TH_always jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=2m" EDP 0 600 168 6 29 4

echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
echo 256 >  /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

./run.sh LOADLEVEL jbb103 1GB_LP_TH_always jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=1g" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 1GB_LP_TH_always jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24 -XX:LargePageSizeInBytes=1g" EDP 0 600 168 6 29 4

echo 0 >  /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

exit

./run.sh LOADLEVEL jbb103 SNC2_8Gr_PnP_Combo jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 SNC2_8Gr_PnP_Combo jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 SNC2_8Gr_PnP_Combo jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8

exit

./runJDK8.sh LOADLEVEL jbb103 Paula jdk1.8-u20 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./runJDK8.sh LOADLEVEL jbb103 Paula jdk1.8-u20 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./runJDK8.sh LOADLEVEL jbb103 Paula jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./runJDK8.sh LOADLEVEL jbb103 Paula jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 3GHz_24Uncore jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 3GHz_24Uncore_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 3GHz_24Uncore jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 3GHz_24Uncore_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 3GHz_24Uncore jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 3GHz_24Uncore_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
exit

./run.sh LOADLEVEL jbb103 PnP_Combo jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 PnP_Combo_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 PnP_Combo_8Gr_R jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=12" EDP 0 600 84 3 15 8
./run.sh LOADLEVEL jbb103 PnP_Combo jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 PnP_Combo_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
./run.sh LOADLEVEL jbb103 PnP_Combo_8Gr_R jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=12" EDP 0 600 84 3 15 8
exit

./run.sh LOADLEVEL jbb103 4_DPT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
exit


./run.sh LOADLEVEL jbb103 Combo1_4Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 Combo1_8Gr jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 8
exit
./run.sh LOADLEVEL jbb103 8_LocalXPT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 9_RemoteXPT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 10_UPI_Prefetch_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 11_OSB_Read_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 12_DeadOnValidLLC_1 jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 13_SnoopThrottle_Enab jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4


./run.sh LOADLEVEL jbb103 7_Specl2M_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh LOADLEVEL jbb103 5_HMLS_Pre_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh LOADLEVEL jbb103 4_DPT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

emon --write-msr 1a4=0
./run.sh LOADLEVEL jbb103 1_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 1_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 1_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh LOADLEVEL jbb103 8_LocalXPT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 12_DeadOnValidLLC_1 jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 13_SnoopThrottle_Enab jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 14_IODC_remoteWCIL_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 15_Dir_AtoS_Enab jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4







emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_Pref_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 16_HT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=12" EDP 0 600 84 3 15 4
./run.sh LOADLEVEL jbb103 16_HT_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=12" EDP 0 600 84 3 15 4

./run.sh LOADLEVEL jbb103 16_HT_Dis_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 16_HT_Dis_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 16_HT_Dis_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 1_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 2_PnP_Prefetcher_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
emon --write-msr 1a4=0
exit

./run.sh LOADLEVEL jbb103 7_SPECI2M_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 7_SPECI2M_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 7_SPECI2M_Dis jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh LOADLEVEL jbb103 1_Base jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 2_PnP_Prefetcher_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_PnP_Prefetcher_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 2_PnP_Prefetcher_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit
./run.sh PRESET jbb103 AVX0-All jdk1.13-b32 "-XX:UseAVX=0 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" ALL 143751 600 168 6 29 4
./run.sh PRESET jbb103 AVX0-All jdk1.14-b36 "-XX:UseAVX=0 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" ALL 146038 600 168 6 29 4

./runAVX.sh PRESET jbb103 AVX3-ALL jdk1.13-b32 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" ALL 139064 600 168 6 29 4
./runAVX.sh PRESET jbb103 AVX3-ALL jdk1.14-b36 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" ALL 140626 600 168 6 29 4



./run.sh LOADLEVEL jbb103 AVX0-All jdk1.14-b36 "-XX:UseAVX=0 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AVX0-All jdk1.14-b36 "-XX:UseAVX=0 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

./run.sh LOADLEVEL jbb103 AVX3-BE jdk1.14-b36 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AVX3-BE jdk1.14-b36 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

./runAVX.sh LOADLEVEL jbb103 AVX3-ALL jdk1.14-b36 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./runAVX.sh LOADLEVEL jbb103 AVX3-ALL jdk1.14-b36 "-XX:UseAVX=3 -Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

exit





emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=1
./run.sh LOADLEVEL jbb103 MLC_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=2
./run.sh LOADLEVEL jbb103 MLC_Spacial_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Spacial_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Spacial_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=4
./run.sh LOADLEVEL jbb103 DCU_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_Streamer_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=8
./run.sh LOADLEVEL jbb103 DCU_IP_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_IP_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_IP_Disabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=e
./run.sh LOADLEVEL jbb103 MLC_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=d
./run.sh LOADLEVEL jbb103 MLC_Spacial_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Spacial_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 MLC_Spacial_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=b
./run.sh LOADLEVEL jbb103 DCU_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_Streamer_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=7
./run.sh LOADLEVEL jbb103 DCU_IP_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_IP_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 DCU_IP_Enabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4

emon --write-msr 1a4=F
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
./run.sh LOADLEVEL jbb103 AllDisabled jdk1.13-b32 "-Xms30720m -Xmx30720m -Xmn29696m -XX:ParallelGCThreads=24" EDP 0 600 168 6 29 4
exit

./run.sh PRESET jbb102 Test jdk1.13-b32 "-XX:ParallelGCThreads=24 -Xms30720m -Xmx30720m -Xmn29696m" EDP 162000 400 168 6 29 4
exit


./run.sh HBIR_RT jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" NONE 0 168 4 30 4
./run.sh HBIR_RT jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" NONE 0 168 4 30 4
./run.sh HBIR_RT jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" NONE 0 168 4 30 4
./run.sh HBIR_RT jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" NONE 0 168 4 30 4
./run.sh LOADLEVEL jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 4 30 4
./run.sh LOADLEVEL jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 4 30 4
./run.sh LOADLEVEL jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 4 30 4
./run.sh LOADLEVEL jbb103 SNC2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=24" EDP 0 600 168 4 30 4

exit
./run.sh LOADLEVEL jbb103 SNC4 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 192 3 48 2
./run.sh LOADLEVEL jbb103 SNC4 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 204 3 48 2
./run.sh LOADLEVEL jbb103 SNC4 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 216 3 48 2
exit

./run.sh LOADLEVEL jbb103 Tier1_216 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 216 1 48 2
./run.sh LOADLEVEL jbb103 Tier1_228 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 228 1 48 2
./run.sh LOADLEVEL jbb103 Tier1_240 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 240 1 48 2
./run.sh LOADLEVEL jbb103 Tier1_252 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 252 1 48 2
exit

./run.sh LOADLEVEL jbb103 Tier1_48 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 48 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_96 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 96 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_144 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 144 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_192 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 192 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_240 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 240 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_288 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 288 48 48 2
./run.sh LOADLEVEL jbb103 Tier1_336 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 336 48 48 2
exit
./run.sh LOADLEVEL jbb103 ICX_24C_Base jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 196 2 24 2
./run.sh LOADLEVEL jbb103 ICX_24C_Base jdk1.13-b32 "-Xms30g -Xmx30g -Xmn28g -XX:ParallelGCThreads=48" EDP 0 600 196 2 24 2
exit

./run.sh LOADLEVEL jbb103 ICX_24C_Tier2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn27g -XX:ParallelGCThreads=24" EDP 0 600 196 7 34 4
./run.sh LOADLEVEL jbb103 ICX_24C_Tier2 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn27g -XX:ParallelGCThreads=24" EDP 0 600 196 7 34 4
./run.sh LOADLEVEL jbb103 ICX_24C_Tier3 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn27g -XX:ParallelGCThreads=24" EDP 0 600 158 53 21 4
./run.sh LOADLEVEL jbb103 ICX_24C_Tier3 jdk1.13-b32 "-Xms30g -Xmx30g -Xmn27g -XX:ParallelGCThreads=24" EDP 0 600 158 53 21 4

exit

./run.sh LOADLEVEL jbb103 ICX_24C_BASE_Fixed jdk1.13-b32 "-Xms29g -Xmx29g -Xmn27g -XX:ParallelGCThreads=48" EDP 0 600 196 7 34 2
./run.sh LOADLEVEL jbb103 ICX_24C_BASE_Fixed jdk1.13-b32 "-Xms29g -Xmx29g -Xmn27g -XX:ParallelGCThreads=48" EDP 0 600 196 7 34 2
./run.sh LOADLEVEL jbb103 ICX_24C_BASE_Fixed jdk1.13-b32 "-Xms29g -Xmx29g -Xmn27g -XX:ParallelGCThreads=48" EDP 0 600 196 7 34 2
exit
