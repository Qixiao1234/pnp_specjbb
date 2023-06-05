#!/bin/bash
#
# Copyright (c) 2017, Intel Corporation
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Intel Corporation nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if [ "$EUID" -ne 0 ]
  then echo "Please run as root / sudo"
  exit
fi
PWD=`pwd`
cleanup() {
cd $PWD
exit
}
trap "cleanup" INT TERM EXIT

SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname "$(readlink -f "$0")"`
RUN_DIR=$SCRIPT_DIR
FIO_DIR=$RUN_DIR/path_to_fio_disk
mkdir -p $FIO_DIR

usage(){
    printf "\nUsage: $SCRIPT_NAME [<options>][<arguments> ...]\n\tThis script will display Server info and optionally perform health check using micro benchmarks on given server list. By default it uses localhost.\n\n"
        printf "Options:\n"
        printf " -c, --check <all> or <[cpu],[mem],[search],[disk]>\n\tSelect micros benchmark components as comma seperated list with no spaces.\n"
        printf " -n, --nodes <host1,[host2]..>\n\tSelect the nodes for health check, as a comma seperate list with no spaces.\n"
        printf " --hosts <hosts_file>\n\tUse a hosts file instead of nodes. Hosts file should have 1 server per line.\n"
        printf " -t, --time <time_in_seconds>\n\tChoose duration for micro benchmarks in seconds. Default is 30s. \n"
        printf " -f, --fio_disk_path <dir path for fio test file>\n\tSpecify the disk path to use for fio (>4GB free). Default is under $RUN_DIR. \n"
        printf " -v, --vm \n\tUse when running in a virtual machine. This will allow MLC to run. \n"
        printf "\nExamples:\n"
        printf " Collect detailed Server Info on local host.\n\t# $SCRIPT_NAME\n"
        printf " Collect server info and run health check on local host using all micro-benchmark components\n\t# $SCRIPT_NAME -c all\n"
        printf " \n"
    exit 1
}

if [ $# -eq 1 ]; then 
case $1 in
    "--help") usage ;;
    "-h") usage ;;
    "-v") true ;;
    "--vm") true ;;
    *) echo Invalid argument used: $1;exit ;;
esac
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--name)
    NAME="$2"
    shift
    ;;
    -v|--vm)
    VM=1
    ;;
    -c|--check)
    COMPONENTS="$2"
    shift
    ;;
    -t|--time)
    TIME="$2"
    shift
    ;;
    -f|--fio_disk_path)
    [ ! -d "$2" ] && echo "FIO disk path is not a valid dir" && exit 1
    FIO_DIR="$2"
    shift
    ;;
    *)
    echo Invalid argument used: $key
    exit
    ;;
esac
shift
done

if [ "$COMPONENTS" = "all" ]; then
  COMPONENTS="cpu,mem,search,disk"
fi
if [ -z $COMPONENTS ]; then COMPONENTS=none;fi

[ -z "$TIME" ] && TIME=30

declare -A cmds=( ["cpu"]="stressng_common cpu" ["mem"]="stressng_common vm" ["search"]="stressng_tsearch" ["disk"]="fio_rwrnd" )
declare -A cmdstxt=( ["cpu"]="stressng_cpu(op/s)" ["mem"]="stressng_mem(op/s)" ["search"]="stressng_search(op/s)" ["disk"]="fio_disk(iops)" )

if [ $COMPONENTS != "none" ]; then
for ck in ${COMPONENTS//,/ }; do
    if [ "${cmds[$ck]+test}" != "test" ]; then
        printf "\ninvalid component: %s\n" $ck
        usage
    fi
done
fi

check_bin() {
  ! hash $1 2>/dev/null
}

stressng_common() {
    printf "\n> stress-ng --$1 0 -t "$TIME"s --metrics-brief: \n"
    $RUN_DIR/stress-ng --$1 0 -t "$TIME"s --metrics-brief 2>&1
}

calc_freq() {
    # run calcfreq on each core on one socket
    num_vcpus=$(lscpu | grep 'CPU(s):' | head -1 | awk '{print $2}')
    threads_per_core=$(lscpu | grep 'Thread(s) per core:' | head -1 | awk '{print $4}')
    num_sockets=$(lscpu | grep 'Socket(s):' | head -1 | awk '{print $2}')
    num_cores=$((num_vcpus / threads_per_core))
    num_cores_per_socket=$((num_cores / num_sockets))
    iterations=100
    # if the first two 'core ids' from /proc/cpuinfo are the same then use -a1 option
    cpu_0_core_id=$(grep 'core id' /proc/cpuinfo | head -1 | awk '{print $4}')
    cpu_1_core_id=$(grep 'core id' /proc/cpuinfo | head -2 | tail -1 | awk '{print $4}')
    if [ $cpu_0_core_id -eq $cpu_1_core_id ]; then
        $RUN_DIR/calcfreq -t$num_cores_per_socket -x$iterations -a1
    else
        $RUN_DIR/calcfreq -t$num_cores_per_socket -x$iterations
    fi
}

turbo_test() {
    tcmd="$RUN_DIR/turbostat -i 2"
    (sh -c "$tcmd 2>/dev/null &";$RUN_DIR/stress-ng --cpu 1 -t 9s 2>&1;$RUN_DIR/stress-ng --cpu 0 -t 5s --metrics-brief 2>&1;kill `ps -e|grep turbostat|awk '{print $1}'`)|awk '$0~"stress" {print $0} $1=="Package" || $1=="CPU" || $1=="Core" {if(f!=1) print $0;f=1} $1=="-" {print $0}'
}

stressng_hdd() {
    $RUN_DIR/stress-ng --hdd 0 --hdd-opts wr-rnd,rd-rnd -t "$TIME"s --metrics-brief 2>/dev/null|awk -v p="hdd  " '$0 ~ p {print $9}'
}

stressng_tsearch() {
    printf "\n> stress-ng --tsearch 0 -t "$TIME"s --metrics-brief: \n"
    $RUN_DIR/stress-ng --tsearch 0 -t "$TIME"s --metrics-brief 2>&1
}

fio_rwrnd() {
    printf "\n> fio --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75: \n"
    mkdir -p $FIO_DIR;$RUN_DIR/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test \
     --filename=$FIO_DIR/fio_test_file --runtime=$TIME --bs=4k --iodepth=64 --size=4G --readwrite=randrw \
     --rwmixread=75 2>/dev/null
}
freq_drv_pol() {
    echo "CPU Freq Driver: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null)"
    echo "CPU Freq Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
}
bios_version() {
    echo $(dmidecode -s bios-version)
}

chk_avx512() {
    $RUN_DIR/avx512test > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
    echo "AVX512TEST: Passed"
    else
    echo "AVX512TEST: Failed"
    fi
}

svr_info() {
    h=$1
    printf "\n--------------- Host $h -----------------\n"
    printf "\n> date -u: \n"
    date -u
    printf "\n> lscpu: \n"
    lscpu
    printf "\n> /proc/cpuinfo: \n"
    cat /proc/cpuinfo | sed '/^\s*$/q'
    printf "\n> /proc/meminfo: \n"
    cat /proc/meminfo
    printf "\n> dmidecode: \n"
    $RUN_DIR/dmidecode
    printf "\n> cpuid -1: \n"
    modprobe msr;modprobe cpuid;$RUN_DIR/cpuid -1
    printf "\n> cpuid -1 -r: \n"
    $RUN_DIR/cpuid -1 -r
    printf "\n> cpu_freq_drv_pol: \n"
    freq_drv_pol
    printf "\n> avx512test: \n"
    chk_avx512
    printf "\n> lsblk -o NAME,MODEL,SIZE,MOUNTPOINT,FSTYPE,TRAN,RQ-SIZE,MIN-IO: \n"
    lsblk -o NAME,MODEL,SIZE,MOUNTPOINT,FSTYPE,TRAN,RQ-SIZE,MIN-IO
    printf "\n> df -h: \n"
    df -h
    printf "\n> lshw -businfo: \n"
    slw=`$RUN_DIR/lshw -businfo`
    echo "$slw"
    nics=$(echo "$slw" | grep network | cut -d' ' -f3) 
    for n in $nics; do
      printf "\n> ethtool $n: \n"
      $RUN_DIR/ethtool $n
      printf "\n> ethtool -i $n: \n"
      $RUN_DIR/ethtool -i $n
    done
    printf "\n> uname -a: \n"
    uname -a
    printf "\n> cat /etc/*-release: \n"
    cat /etc/*-release
    printf "\n> spectre-meltdown-checker: \n"
    $RUN_DIR/spectre-meltdown-checker.sh --batch text
    printf "\n> lsmod: \n"
    lsmod
    printf "\n"
    echo "> ps -eo user,pid,%cpu,%mem,rss,command --sort=-%cpu,-pid | grep -v ]$: "
    printf "\n"
    ps -eo user,pid,%cpu,%mem,rss,command --sort=%cpu,-pid | grep -v ]$
    printf "\n> Memory MLC Loaded Latency Test: \n"
    # if running in a VM
    if [ ! -z "$VM" ]; then
        $RUN_DIR/mlc --loaded_latency -e -r
    else
        $RUN_DIR/mlc --loaded_latency
    fi
    printf "\n> CPU Turbo Test: \n"
    turbo_test
    printf "\n> Measure Turbo: \n"
    calc_freq 
    printf "\n> Memory MLC Bandwidth: \n"
    # if running in a VM
    if [ ! -z "$VM" ]; then
        $RUN_DIR/mlc --bandwidth_matrix -e
    else
        $RUN_DIR/mlc --bandwidth_matrix
    fi
    printf "\n> rdmsr 0x1a4 -f 3:0: \n"
    $RUN_DIR/rdmsr -f 3:0 0x1a4
    printf "\n> rdmsr 0x1b0 -f 3:0: \n"
    $RUN_DIR/rdmsr -f 3:0 0x1b0
    # if not running in a VM
    if [ -z "$VM" ]; then
        printf "\n> rdmsr 0x1ad: \n"
        $RUN_DIR/rdmsr 0x1ad
        printf "\n> rdmsr 0x1ae: \n"
        $RUN_DIR/rdmsr 0x1ae
    fi
    printf "\n> ipmitool sel time get: \n"
    modprobe ipmi_devintf;modprobe ipmi_si;$RUN_DIR/ipmitool sel time get
    printf "\n> ipmitool sel elist | tail -n20: \n"
    $RUN_DIR/ipmitool sel elist | tail -n20 | cut -d'|' -f2-
    printf "\n> ipmitool chassis status: \n"
    $RUN_DIR/ipmitool chassis status
    printf "\n> ipmitool sdr list full: \n"
    $RUN_DIR/ipmitool sdr list full
    printf "\n\n"
}

svr_info $NAME
for ck in ${COMPONENTS//,/ }; do
    ${cmds["$ck"]}
done
printf "\n> End: \n"
echo "completed on $NAME"
