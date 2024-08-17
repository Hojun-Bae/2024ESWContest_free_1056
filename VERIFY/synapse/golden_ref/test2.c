#include <stdio.h>
#include <stdlib.h>

#define MEM_DEPTH 480
#define NUM_SYNAPSE 12

int main(int argc, char **argv) {
	if(argc != 2){
		printf("Usage : <executable> <srand_val>\n");
		return -1;
	}
	srand(atoi(argv[1]));
	FILE *fp_in_node, *fp_in_wegt, *fp_ot_rslt;
	fp_in_node = fopen("ref_c_rand_input_node.txt","r");
	fp_in_wegt = fopen("ref_c_rand_input_wegt.txt","r");
	fp_ot_rslt = fopen("ref_c_result2.txt","w");
	
	unsigned char IN_NODE[480][NUM_SYNAPSE]; // 8b 
	unsigned char IN_WEGT[480][NUM_SYNAPSE]; // 8b
	unsigned 	  OT_RSLT[MEM_DEPTH] = {0,}; // 32b  // init 0
	unsigned long RSLT = 0;

	for (int i = 0; i<MEM_DEPTH; i++){
		RSLT = 0;
		for (int core = 0; core < NUM_SYNAPSE; core++) {
			fscanf (fp_in_node, "%d ", &IN_NODE[i][core]);  // order 0 1
			fscanf (fp_in_wegt, "%d ", &IN_WEGT[i][core]);  // order 0 1
			RSLT += IN_NODE[i%48][core] * IN_WEGT[i][core];
		}
		OT_RSLT[i] = RSLT; 
	}
	RSLT = 0;
	for (int i = 0; i < MEM_DEPTH; i++) {
		RSLT += OT_RSLT[i];
		if(i%48==47) {
			fprintf (fp_ot_rslt, "%lu\n", RSLT);
			RSLT = 0;
		}	
	}
	fclose(fp_in_node);
	fclose(fp_in_wegt);
	fclose(fp_ot_rslt);
	return 0;
}

