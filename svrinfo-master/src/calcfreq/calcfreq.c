#define _GNU_SOURCE

#include <sys/timeb.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sched.h>
#include <errno.h>

typedef unsigned long long int UINT64;
typedef long long int __int64;

void NopLoop(__int64 iter);
void Calibrate(UINT64   *ClksPerSec);

__int64 iterations = 100LL*1000000LL; // 100 million iteration as default

struct _p {
	
	__int64 total_time;
	__int64 iterations;
	int	id;
	int id2;
	__int64 junk[5];
} param[128];

int BindToCpu(int cpu_num);

pthread_t td[1024];
UINT64 len=0;
UINT64 num_cpus=0;
UINT64 freq;
double NsecClk;
__int64 cycles_expected, actual_cycles, running_freq;

int cpu_assignment=0;

static inline unsigned long rdtsc ()
{
  unsigned long var;
  unsigned int hi, lo;

  asm volatile ("rdtsc" : "=a" (lo), "=d" (hi));
  var = ((unsigned long long int) hi << 32) | lo;

  return var;
}

void BusyLoop()
{
	__int64 start, end;
	
	// run for about 200 milliseconds assuming a speed of 2GHz - need not be precise
	// this is done so the core has enough time to ramp up the frequency

	start = rdtsc();
	while (1) {
		end = rdtsc();
		if ((end - start) > 400000000LL) { break;  } 
	}

}
unsigned int execNopLoop(void* p)
{
	char *buf;
	int id, blk_start,i,j;
	__int64 start, end, delta;
	struct _p *pp;
	
	pp = (struct _p *)p; // cpu#
	BindToCpu(pp->id); // pin to that cpu
	pp->total_time = 0;

	// crank up the frequency to make sure it reaches the max limit
	BusyLoop();
	
	// repeat the measurement for 3 times and take the best value
	
	for (i=0; i < 3; i++) {
		asm ("mfence");
		start = rdtsc();
		asm ("mfence");
		NopLoop((__int64)iterations);
		asm ("mfence");
		end = rdtsc();
		asm ("mfence");
		delta = end - start;
		if (delta > pp->total_time) pp->total_time = delta;
	}
	
}


void Usage(const char* error)
{
	if (error) {
		fprintf(stderr, "%s\n\n", error);
	}
	fprintf(stderr, "./calcfreq -tn -xn -an\n");
	fprintf(stderr, "   -t : number of physical cores to run this on\n");
	fprintf(stderr, "   -x : iterations in millions\n");
	fprintf(stderr, "   -a : set to 1 if HT threads get consecutive cpu#s\n");
	exit(0);

}
int main(int argc, char **argv)
{
	int i, j, rc, r, total_blocks, total_freed=0, idx;
	UINT64 len_actual;
	UINT64 cpuid[1024];

	printf("CalcFreq v1.0\n");
	for (i = 1; (i < argc && argv[i][0] == '-'); i++) {
		switch (argv[i][1]) {
			case '?': {
				/* Help - print usage and exit */
				Usage((char*) 0);
			}
			
			case 't': {
				num_cpus = atoi(&argv[i][2]);
				break;
			}

			case 'a': {
				cpu_assignment = atoi(&argv[i][2]);
				break;
			}

			case 'x': {
				iterations = (UINT64)(atoi(&argv[i][2]))*1000000LL;
				break;
			}

			default: {
				fprintf(stderr, "Invalid Argument:%s\n", &argv[i][0]);
				Usage((char*) 0);
				break;
			}
		}
	}
	// ramp up the processor frequency and measure the TSC frequency
	BusyLoop();
	Calibrate(&freq); // Get the P1 freq

	cycles_expected = iterations * 200/4; // we are executing 200 instructions and in each cycle we can retire 4
	for (idx = 1; idx <= num_cpus; idx++) {
		__int64 tt;
		int cnt;
		for (i=0, j=0; i < idx; i++, j+=2) {
			if (cpu_assignment == 1) {
				// CPU#s are assigned consecutively. i.e cpu0&1 will map to the same physical core
				param[i].id = j;
			}
			else {
				param[i].id = i;
			}
			rc = pthread_create(&td[i], NULL, (void*)execNopLoop, (void*)&param[i]);
		}
		cnt=0;
		tt=0;
		for (i=0; i < idx; i++) {
			pthread_join(td[i], NULL);
			tt += param[i].total_time;
			cnt++;			
		}
		actual_cycles = tt / cnt;
		running_freq = (__int64) ((double) cycles_expected * (double) freq / (double) actual_cycles);
		printf("%d-core turbo\t%ld MHz\n", cnt, running_freq/1000000);
		
	}
	return 0;
}

// pin to a specific cpu

int BindToCpu(int cpu_num)
{
    long status;

    cpu_set_t cs;

    CPU_ZERO (&cs);
    CPU_SET (cpu_num, &cs);
    status = sched_setaffinity (0, sizeof(cs), &cs);
    if (status < 0) {
        printf ("Error: unable to bind thread to core %d\n", cpu_num);
        exit(1);
    }
    return 1;
}

// 200 instuctions are executed per iteration and in each cycle we can retire 4 of these instructions
void NopLoop(__int64 iter)
{
	asm (
	"xor %%r9, %%r9\n\t"
	"mov %0,%%r8\n\t"
"loop1:\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"xor %%rax, %%rax\n\t"
	"inc %%r9\n\t"
	"cmp %%r8, %%r9\n\t"
	"jb loop1\n\t"
	
	::"r"(iter));
}

static inline unsigned long long int GetTickCount()
{//Return ns counts
        struct timeval tp;
        gettimeofday(&tp,NULL);
        return tp.tv_sec*1000+tp.tv_usec/1000;
}

// Get P1 freq
void Calibrate(UINT64   *ClksPerSec)
{
        UINT64  start;
        UINT64  end;
        UINT64  diff;

        unsigned long long int  starttick, endtick;
        unsigned long long int  tickdiff;

        endtick = GetTickCount();

        while(endtick == (starttick=GetTickCount()) );

        asm("mfence");
		start = rdtsc();
        asm("mfence");
        while((endtick=GetTickCount())  < (starttick + 500));
        asm("mfence");
        end = rdtsc();
        asm("mfence");
        //      printf("start tick=%llu, end tick=%llu\n",starttick,endtick);

        diff = end - start;
        tickdiff = endtick - starttick;
        //      printf("end=%llu,start=%llu,diff=%llu\n",end,start,diff);
        *ClksPerSec = ( diff * (UINT64)1000 )/ (unsigned long long int)(tickdiff);
        NsecClk = (double)1000000000 / (double)(__int64)*ClksPerSec;
        printf("P1 freq = %d MHz\n",*ClksPerSec/1000000);
}
