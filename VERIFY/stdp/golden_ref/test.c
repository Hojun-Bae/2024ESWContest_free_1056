#include <stdio.h>
#include <stdlib.h>

#define N_EXC 18
#define IMG_ROWS 24
#define IMG_COLS 24
#define ETA_PRE 9
#define ETA_POST 3 

int main(int argc, char **argv) {
	if(argc != 2){
		printf("Usage : <executable> <srand_val>\n");
		return -1;
	}
	srand(atoi(argv[1]));

	int t, i, j, k;

	FILE *fp_in_pre, *fp_in_post, *fp_in_x1, *fp_in_y1, *fp_in_y2_buf, *fp_in_wegt, *fp_ot_rslt;
	fp_in_pre = fopen("ref_c_rand_input_pre.txt","w");
	fp_in_post = fopen("ref_c_rand_input_post.txt","w");
	fp_in_x1 = fopen("ref_c_rand_input_x1.txt","w");
	fp_in_y1 = fopen("ref_c_rand_input_y1.txt","w");
	fp_in_y2_buf = fopen("ref_c_rand_input_y2_buf.txt","w");
	fp_in_wegt = fopen("ref_c_rand_input_wegt.txt","w");
	fp_ot_rslt = fopen("ref_c_result.txt","w");
	
	unsigned char post[N_EXC]; // 8b 
	unsigned char pre[IMG_ROWS][IMG_COLS]; // 8b 
	
	long long x1[IMG_ROWS][IMG_COLS] = {0,}; // 8b 
	long long y1[N_EXC] = {0,}; // 8b 
	long long y2_buf[N_EXC] = {0,}; // 8b 

	long long wegt[N_EXC][IMG_ROWS][IMG_COLS]; // 16b

	long long delta;

	// Weight set
	for(i=0; i<N_EXC; i++) {
		for(j=0; j<IMG_ROWS; j++) { 
			for(k=0; k<IMG_COLS; k++) {
				wegt[i][j][k] = rand()%(1<<16);
				fprintf(fp_in_wegt, "%d\n", wegt[i][j][k]);
			}
		}
	}

	for(t=0; t<50; t++) {
		// pre
		for(i=0; i<IMG_ROWS; i++) {
			for(j=0; j<IMG_COLS; j++) {
				pre[i][j] = rand()%2;
				fprintf(fp_in_pre, "%d\n", pre[i][j]);
				x1[i][j] = rand()%(1<<16);
				fprintf(fp_in_x1, "%d\n", x1[i][j]);
			}
		}

		// post
		for(i=0; i<N_EXC; i++) {
			post[i] = rand()%2;
			y1[i] = rand()%(1<<16);
			y2_buf[i] = rand()%(1<<16);
			fprintf(fp_in_post, "%d\n", post[i]);
			fprintf(fp_in_y1, "%d\n", y1[i]);
			fprintf(fp_in_y2_buf, "%d\n", y2_buf[i]);
		}
			
		// STDP
		for(i=0; i<N_EXC; i++) {
			for(j=0; j<IMG_ROWS; j++) {
				for(k=0; k<IMG_COLS; k++) {
					delta = 0;
					if(post[i]) 
						delta += (x1[j][k] * y2_buf[i]) >> (ETA_POST + 16);
					if(pre[j][k])
						delta -= y1[i] >> ETA_PRE;
					if(t%10 == 9)
						delta -= 1;
					wegt[i][j][k] += delta;
					wegt[i][j][k] = (wegt[i][j][k] < 0) ? 0 : wegt[i][j][k];
					wegt[i][j][k] = (wegt[i][j][k] > 0xffff) ? 0xffff : wegt[i][j][k];
					fprintf(fp_ot_rslt, "%lld\n", wegt[i][j][k]);
				}
			}
		}
	}
	fclose(fp_in_pre);
	fclose(fp_in_post);
	fclose(fp_in_x1);
	fclose(fp_in_y1);
	fclose(fp_in_y2_buf);
	fclose(fp_in_wegt);
	fclose(fp_ot_rslt);
	
	return 0;
}

