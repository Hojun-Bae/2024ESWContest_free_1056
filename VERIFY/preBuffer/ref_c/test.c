#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N_IMG 784
#define N_INPUT 576
#define N_EXC 144
#define N_INH 144

#define IMG_ROWS 24
#define IMG_COLS 24

unsigned short mixBits(unsigned short input);

int main(void) {
	int neuron_idx, i, j, k, t, n;

	// LFSR 
	unsigned short out[4];
    unsigned short next_out;
    unsigned short mix[4];

	unsigned int img[IMG_ROWS][IMG_COLS];

	// Spike memory
	unsigned char pre_spike[IMG_ROWS][IMG_COLS];

	// Synaptic trace
	long long x1[IMG_ROWS][IMG_COLS] = {0,};
	
	FILE *f_img, *f_pix, *f_rand, *f_spike, *f_trace;

	// Open the file for writing
	f_img = fopen("mnist.txt", "r");
	f_pix = fopen("pixel.txt", "w");
	f_rand = fopen("lfsr.txt", "w");
	f_spike = fopen("input_spike.txt", "w");
	f_trace = fopen("x_trace.txt", "w");

	for(i=0; i<4; i++) {
		out[i] = 1000 + i;
		mix[i] = mixBits(out[i]);
	}

	fscanf(f_img, "%d", &t);
	for(i=0; i<24; i++) 
		for(j=0; j<24; j++) 
			fscanf(f_img, "%d", &img[i][j]);

	// Read MNIST data from CSV file
	for(t=0; t<800; t++) {
		for(i=0; i<24; i++) {
			for(j=0; j<6; j++) {
				for(k=0; k<4; k++) {
					if((img[i][j*4 + k] << 2) > mix[k]) {
						pre_spike[i][j*4 + k] = 1;
						x1[i][j*4 + k] = 0xffff;
					} else {
						pre_spike[i][j*4 + k] = 0;
						x1[i][j*4 + k] -= x1[i][j*4 + k] >> (1 + 3);
					}
					fprintf(f_spike, "%d, ", pre_spike[i][j*4 + k]);
					fprintf(f_trace, "%d, ", x1[i][j*4 + k]);
					fprintf(f_pix, "%d, ", img[i][j*4 + k] << 2);
					fprintf(f_rand, "%d, ", mix[k]);
					next_out = ((out[k] >> 15) ^ (out[k] >> 13) ^ (out[k] >> 12) ^ (out[k] >> 10)) & 0x0001;
					out[k] = (out[k] << 1) | next_out;
					mix[k] = mixBits(out[k]);
				}
				fprintf(f_pix, "\n");
				fprintf(f_rand, "\n");
			}
		}
		fprintf(f_spike, "\n");
		fprintf(f_trace, "\n");
	}
	

	fclose(f_img);
	fclose(f_rand);
	fclose(f_spike);
	fclose(f_trace);

	return 0;
}

unsigned short mixBits(unsigned short input) {
	return
		((input & 0x0002) << 14) |  // Extract and move bit 1 to bit 15
		((input & 0x0040) << 8)  |  // Extract and move bit 6 to bit 14
		((input & 0x0008) << 10) |  // Extract and move bit 3 to bit 13
		((input & 0x2000) >> 1)  |  // Extract and move bit 13 to bit 12
		((input & 0x0800) << 0)  |  // Extract and move bit 11 to bit 11
		((input & 0x0100) << 2)  |  // Extract and move bit 8 to bit 10
		((input & 0x0004) << 7)  |  // Extract and move bit 2 to bit 9
		((input & 0x0001) << 8)  |  // Extract and move bit 0 to bit 8
		((input & 0x8000) >> 8)  |  // Extract and move bit 15 to bit 7
		((input & 0x0010) << 2)  |  // Extract and move bit 4 to bit 6
		((input & 0x0080) >> 2)  |  // Extract and move bit 7 to bit 5
		((input & 0x0020) >> 1)  |  // Extract and move bit 5 to bit 4
		((input & 0x4000) >> 11) |  // Extract and move bit 14 to bit 3
		((input & 0x0400) >> 8)  |  // Extract and move bit 10 to bit 2
		((input & 0x1000) >> 11) |  // Extract and move bit 12 to bit 1
		((input & 0x0200) >> 9);    // Extract and move bit 9 to bit 0
}
