


The SPECjbb 2015 (https://www.spec.org/jbb2015/) benchmark has been developed to measure performance based on the latest Java application features. 
It is relevant to all audiences who are interested in Java server performance, including JVM vendors, hardware developers, Java application developers, researchers and members of the academic community.

Types of Runs
1.	HBIR_RT – Creates an RT curve that stepps up the IR in steps of 1% to calculate the maximum throughput and the critical throughput. (2 hrs)
2.	LOADLEVEL - Run the benchmark at steady state for data collection. (2.5 hrs)
3.	PRESET - Usually run at 0.95*MaxThroughput value for a given amount of time. (less than 30 min) 


Inside SPECjbb2015
GoMLQ.sh – A script where we can queue multiple runs which will execute one after another.
run.sh - The primary script for executing a SPECjbb run.

Setup
1. Make sure that this is cloned in a directory named workloads so that the pwd command returns the path /workloads/SPECjbb2015/
2. Download and unpack the JDK version <JDK_VERSION_TAG> you are going to use in the path /workloads/JVM/ directory so that the final java path would /workloads/JVM/<JDK_VERSION_TAG>/

Executing a run
 ./run.sh [TYPE] [kitVers] [tag]  [JDKVersion]  [JVMopt] [CollectionType]

TYPE - HBIR_RT or LOADLEVEL or PRESET
KitVers - the jbb kit version. We use jbb102
tag - just a tag for the run name, anything is fine eg, test
JDKVersion - The <JDK_VERSION_TAG> that you put in /workloads/JVM/   (see setup section, step 2)
JVMopt - the JVM option's you want to set in " "
CollectionType - The datacollection that you want to use, ie, EMON, SEP, PAT. Make sure all these collection scripts are in /workloads/ directory under the tag name.
                eg: PAT, EDP, SEP, PERF, NONE. 
                If you give NONE as the option, then no data collection is launched.

For HBIR_RT runs
 ./run.sh HBIR_RT jbb102 [tag] [JDKVersion] [JVMopt] [CollectionType] [initialIR]
 
 
 For LOADLEVEL runs
  ./run.sh LOADLEVEL jbb102 [tag] [JDKVersion] [JVMopt] [CollectionType] [initialIR] [RUNTIME]


For PRESET runs
 ./run.sh PRESET jbb102 [tag] [JDKVersion] [JVMopt] [CollectionType] [IR] [RUNTIME]
 
 IR - Injection rate usually set at MaxThroughput *0.95 
 
 
 RUNTIME -the time for which the benchmark should run for (in seconds). Make sure the RUNTIME set is more than 600s
 initialIR - The initial injection rate used for the run. Usually 0 as we start from IR at 0%



