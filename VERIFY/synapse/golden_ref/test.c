#include <stdio.h>
#include <stdlib.h>

#define MEM_DEPTH 432
#define NUM_SYNAPSE 24

int main(int argc, char **argv) {
	if(argc != 2){
		printf("Usage : <executable> <srand_val>\n");
		return -1;
	}
	srand(atoi(argv[1]));
	FILE *fp_in_node, *fp_in_wegt, *fp_ot_rslt;
	fp_in_node = fopen("ref_c_rand_input_node.txt","w");
	fp_in_wegt = fopen("ref_c_rand_input_wegt.txt","w");
	fp_ot_rslt = fopen("ref_c_result.txt","w");
	
	unsigned char IN_NODE[NUM_SYNAPSE]; // 8b 
	unsigned short IN_WEGT[NUM_SYNAPSE]; // 16b
	unsigned long long  OT_RSLT[MEM_DEPTH] = {0,}; // 32b  // init 0
	unsigned long RSLT = 0;

	for (int i = 0; i<MEM_DEPTH; i++){
		RSLT = 0;
		for (int core = 0; core < NUM_SYNAPSE; core++) {
			IN_NODE[core] = rand()%2; // 0~1 1b
			IN_WEGT[core] = rand()%(1<<16); // 16b
			RSLT += IN_NODE[core] * IN_WEGT[core];
			fprintf (fp_in_node, "%d\n", IN_NODE[core]);  // order 0 1
			fprintf (fp_in_wegt, "%d\n", IN_WEGT[core]);  // order 0 1
		}
		OT_RSLT[i] = RSLT; 
	}
	RSLT = 0;
	for (int i = 0; i < MEM_DEPTH; i++) {
		RSLT += OT_RSLT[i];
		if(i%24==23) {
			fprintf (fp_ot_rslt, "%lu\n", RSLT);
			RSLT = 0;
		}	
	}
	fclose(fp_in_node);
	fclose(fp_in_wegt);
	fclose(fp_ot_rslt);
	return 0;
}

