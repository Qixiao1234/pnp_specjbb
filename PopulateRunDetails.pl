#! /bin/perl -w
use Cwd;

use lib qw(..);
use POSIX;


# -----------------------------------------------------------
# Start here
# -----------------------------------------------------------


$command = "pwd";
system($command);

$FILESYSTEM =`mount`;
if($FILESYSTEM =~ / type (.*) .*/) {
	$file_system = $1;
	print "\n File system type = $file_system \n";
}

print "\n-------- Initiating PopulateRunDetails script. ------\n";

#if(open(IN, "<","../../svrinfo-master/svr_info.json")){   	# testing
if(open(IN, "<","svr_info.json")){							# for production
	print "\n Server info file found! \n";
	while(<IN>){
		if($_ =~ /"OS": "(.+)"/ && !(length $OS)){
			$OS = $1;
		} elsif($_ =~ /"Current CPU Freq MHz": "(.+)"/ && !(length $CPUFreq)){
			$CPUFreq = $1;
			print "\n_______CPUFreq : $CPUFreq _________\n";
		} elsif($_ =~ /"Sockets": "(.+)"/ && !(length $Sockets)){
			$Sockets = $1;
			print "\n_______Sockets : $Sockets _________\n";

		} elsif($_ =~ /"Total CPU\(s\)": "(.+)"/ && !(length $CPUs)){
			$CPUs = $1;
			print "\n_______ CPUs : $CPUs _________\n";

		} elsif($_ =~ /"MemTotal": "(.+)"/ && !(length $TotalMem)){
			$TotalMemKB = $1;
			if($TotalMemKB =~ /([0-9]+)\s*kB/){
				$TotalMemKB = $1;
				$TotalMem = ceil($TotalMemKB/(1024*1024));   # TO BE REVAMPED, CEIL USED
			}
			print "\n_______ TotalMem : $TotalMem _________\n";

		} elsif($_ =~ /"NUMA Nodes": "(.+)"/ && !(length $NoOfNumaNodes)){
			#$NoOfNumaNodes = $1;
		} elsif($_ =~ /"Kernel": "(.+)"/ && !(length $KernalVersion)){
			$KernalVersion = $1;
			print "\n_______ KernalVersion : $KernalVersion _________\n";

		} elsif($_ =~ /"Model Name": "(.+)"/ && !(length $CPUModelName)){
			$CPUModelName = $1;
			print "\n_______ CPUModelName : $CPUModelName _________\n";

		} elsif($_ =~ /"Manufacturer": "(.+)"/ && !(length $MemManufacturer)){
			$MemManufacturer = $1;
			print "\n_______ MemManufacturer : $MemManufacturer _________\n";

		} elsif($_ =~ /"Part": "(.+)"/ && !(length $MemPart)){
			$MemPart = $1;
			print "\n_______ MemPart : $MemPart _________\n";

		} elsif($_ =~ /"ConfiguredSpeed": "(.+)"/ && !(length $MemConfiguredSpeed)){
			$MemConfiguredSpeed = $1;
			print "\n_______ MemConfiguredSpeed : $MemConfiguredSpeed _________\n";

		} elsif($_ =~ /"Size": "(.*)"/ && !(length $MemSize)){ 
			$MemSize = $1;
			print "\n_______ MemSize : $MemSize _________\n";

		} elsif($_ =~ /"Type": "(.*)"/ && !(length $MemType)){
			$MemType = $1;
			print "\n_______ MemType : $MemType _________\n";

		} 
		
		
		elsif($_ =~ /"L1d Cache": "(\d+)K"/ && !(length $L1d)){
			$L1d = $1;
			if($L1d >= 1024) {
				$L1d = ceil($L1d/1024);
				$L1d = $L1d.' MB';
			} else{
				$L1d = $L1d.' KB';
			}
		} elsif($_ =~ /"L1i Cache": "(\d+)K"/ && !(length $L1i)){
			$L1i = $1;
			if($L1i >= 1024) {
				$L1i = ceil($L1i/1024);
				$L1i = $L1i.' MB';
			} else{
				$L1i = $L1i.' KB';
			}
		} elsif($_ =~ /"L2 Cache": "(\d+)K"/ && !(length $L2)){
			$L2 = $1;
			if($L2 >= 1024) {
				$L2 = ceil($L2/1024);
				$L2 = $L2.' MB';
			} else{
				$L2 = $L2.' KB';
			}
		} elsif($_ =~ /"L3 Cache": "(\d+)K"/ && !(length $L3)){
			$L3 = $1;
			if($L3 >= 1024) {
				$L3 = ceil($L3/1024);
				$L3 = $L3.' MB';
			} else{
				$L3 = $L3.' KB';
			}
		}
	}
} else{
	print "\n !!!! Couldnt fetch SVR info json file. !!!!\n";
	print "\n-------- Terminating PopulateRunDetails script, due to lack of svr information. --------\n";
	exit 0;
}


if(open(IN, "+<","config/template-M.raw") && open(OUT,">","config/temp.raw")){ 
	print "\n******** Populating template file. ********\n";
	while(<IN>){
		if($_ =~ /<<TOTAL_MEMORY>>/ && $TotalMem){
			$_ =~ s/<<TOTAL_MEMORY>>/$TotalMem/g;
		} elsif($_ =~ /<<TOTAL_CHIPS>>/ && $Sockets){
			$_ =~ s/<<TOTAL_CHIPS>>/$Sockets/g;
		} elsif($_ =~ /<<TOTAL_CORES>>/ && $CPUs){
			$Cores = $CPUs/2;
			$_ =~ s/<<TOTAL_CORES>>/$Cores/g;
		} elsif($_ =~ /<<TOTAL_THREADS>>/ && $CPUs){
			$_ =~ s/<<TOTAL_THREADS>>/$CPUs/g;
		}
		
		  elsif($_ =~ /<<CHIPS_PER_SYSTEM>>/ && $Sockets){
			$_ =~ s/<<CHIPS_PER_SYSTEM>>/$Sockets/g;
		} elsif($_ =~ /<<CORES_PER_SYSTEM>>/ && $CPUs){
			$CoresPerSystem = $CPUs/2;
			$_ =~ s/<<CORES_PER_SYSTEM>>/$CoresPerSystem/g;
		} elsif($_ =~ /<<CORES_PER_CHIP>>/ && $CPUs && $Sockets){
			$CoresPerChip = $CPUs/(2*$Sockets);
			$_ =~ s/<<CORES_PER_CHIP>>/$CoresPerChip/g;
		} elsif($_ =~ /<<THREADS_PER_SYSTEM>>/ && $CPUs){
			$_ =~ s/<<THREADS_PER_SYSTEM>>/$CPUs/g;
		} elsif($_ =~ /<<THREADS_PER_CORE>>/ && $CPUs && $Sockets){
			$ThreadsPerCore = $CPUs/$Sockets;
			$_ =~ s/<<THREADS_PER_CORE>>/$ThreadsPerCore/g;
		} elsif($_ =~ /<<CPU_FREQUENCY>>/ && $CPUFreq){
			$_ =~ s/<<CPU_FREQUENCY>>/$CPUFreq/g;
		}
		
		elsif($_ =~ /<<MEMORY_DIMMS>>/){   
			if( (length $TotalMemKB) &&  (length $MemSize)) {
				if($MemSize =~ /([0-9]+) MB/){
					$MemSize = ceil($1/1024);
				} elsif($MemSize =~ /([0-9]+) kB/) {
					$MemSize = ceil($1/(1024*1024));
				} elsif($MemSize =~ /([0-9]+) GB/) {
					$MemSize = $1;
				}
				$NoOfMem = ceil($TotalMem/$MemSize);
				$_ =~ s/<<MEMORY_DIMMS>>/$NoOfMem X $MemSize GB/g;
			}
		} elsif($_ =~ /<<MEMORY_DETAILS>>/ && $MemSize && $MemType && $MemConfiguredSpeed){
			$_ =~ s/<<MEMORY_DETAILS>>/$MemSize GB @ $MemConfiguredSpeed $MemType/g;
		} elsif($_ =~ /<<FILE_SYSTEM>>/ && $file_system){
			$_ =~ s/<<FILE_SYSTEM>>/$file_system/g;
		} elsif($_ =~ /<<CPU_CHARACTERISTICS>>/ && $CPUModelName){
			$_ =~ s/<<CPU_CHARACTERISTICS>>/$CPUModelName/g;
		}	
		
		 elsif($_ =~ /<<KERNAL_VERSION>>/ && $KernalVersion){
			$_ =~ s/<<KERNAL_VERSION>>/$KernalVersion/g;
		} elsif($_ =~ /<<OS_NAME>>/ && $OS){
			$_ =~ s/<<OS_NAME>>/$OS/g;
		} elsif($_ =~ /<<CPU_NAME>>/ && $CPUModelName){
			$_ =~ s/<<CPU_NAME>>/$CPUModelName/g;
		} 
		
		elsif($_ =~ /<<L1_CACHE>>/ && $L1i && $L1d){
			$_ =~ s/<<L1_CACHE>>/$L1i I + $L1d D on chip per core/g;
		} elsif($_ =~ /<<L2_CACHE>>/ && $L2){
			$_ =~ s/<<L2_CACHE>>/$L2 \(I+D\) on chip per core/g;
		} elsif($_ =~ /<<L3_CACHE>>/ && $L3){
			$_ =~ s/<<L3_CACHE>>/$L3 \(I+D\) on chip per core/g;
		}
		
		#/bin/perl -p -i -e "s/<<CPU_NAME>>/$CPUModelName/g" config/temp.raw;

		
		print OUT $_;
	}
	close IN;
	close OUT;
	
	$command ="rm config/template-M.raw";
	system($command);
	
	$command ="mv config/temp.raw config/template-M.raw";
	system($command);
	
} else{
	print "\n !!!!!!Couldnt configure template-M file using server info. !!!!!!!\n"
}

print "\n-------- Terminating PopulateRunDetails script. --------\n";

exit 0;

