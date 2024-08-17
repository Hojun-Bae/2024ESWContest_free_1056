#include "snn.h"

#define MAX_LINE_LENGTH 10000
#define NUM_ROWS 40000  // MNIST training set size
#define NUM_COLS 785    // 1 label + 28x28 pixels
#define TRAIN 60000

//#define PRINT

int main(void) {

	struct timespec  begin, end, buf;

	int neuron_idx, i, j, k, t, n;

	// LFSR 
	unsigned short out[8][IMG_COLS];
    unsigned short next_out;
    unsigned short mix[8][IMG_COLS];
	unsigned short out_ipt[4];
	unsigned short mix_ipt[4];

	for(i=0; i<8; i++) {
		for(j=0; j<IMG_COLS; j++) {
			out[i][j] = i + j*101 + 10001;
			mix[i][j] = mixBits(out[i][j]);
		}
	}

	// MNIST data
	const char* filename = "../../dataset/mnist_train.csv";
	MNIST *mnist_data = (MNIST*)malloc(NUM_ROWS * sizeof(MNIST));

	// Spike memory
	unsigned char pre_spike[IMG_ROWS][NUM_COLS];
	unsigned char post_spike[N_EXC] = {0,};
	unsigned char post_spike_cnt[N_EXC] = {0,};

	int digit[N_EXC][10] = {0,};

	// Excitatory 
	LIF exc_neuron[N_EXC];

	// Weight memory
	long long weight[N_EXC][IMG_ROWS][IMG_COLS];

	// Synaptic trace
	long long x1[IMG_ROWS][IMG_COLS] = {0,};
	long long y1[N_EXC] = {0,};
	long long y2[N_EXC] = {0,};
	long long y2_buf[N_EXC] = {0,};

	long long inh_current, inh_current_buf, exc_current;
	long long delta;
	unsigned int max, up;

	unsigned char idx;
	
	FILE *learned, *exc_thresh, *class, *f_init;
#ifdef PRINT
	FILE *f_mem, *f_x, *f_input, *f_output, *f_y1, *f_y2_buf, *f_inh, *f_exc, *f_vt, *f_acc;
	f_mem = fopen("exc_membrane.csv", "w");
	f_x = fopen("x_trace.csv", "w");
	f_input = fopen("input_spike.csv", "w");
	f_output = fopen("output_spike.csv", "w");
	f_y1 = fopen("y1_trace.csv", "w");
	f_y2_buf = fopen("y2_trace_buf.csv", "w");
	f_inh = fopen("inh_conductance.csv", "w");
	f_exc = fopen("exc_conductance.csv", "w");
	f_vt = fopen("exc_threshold.csv", "w");
	f_acc = fopen("acc.csv", "w");
#endif

	// Open the file for writing
	learned = fopen("learn_weight.txt", "w");
	exc_thresh = fopen("exc_threshold.txt", "w");
	class = fopen("neuron_class.txt", "w");
	f_init = fopen("init_weight.txt", "w");

	// Weight reset
#ifdef CUT
	for(t=0; t<8; t++) {
		for(neuron_idx=0; neuron_idx<18; neuron_idx++) {
			for(i=0; i<IMG_ROWS; i++) {
				for(j=0; j<IMG_COLS; j++) {
					weight[t*18+neuron_idx][i][j] = mix[t][j] >> 2;
					next_out = ((out[t][j] >> 15) ^ (out[t][j] >> 13) ^ (out[t][j] >> 12) ^ (out[t][j] >> 10)) & 0x0001;
					out[t][j] = (out[t][j] << 1) | next_out;
					mix[t][j] = mixBits(out[t][j]);
					fprintf(f_init, "%d\n", weight[t*18+neuron_idx][i][j]);
				}
			}
		}
	}
#else
	for(t=0; t<8; t++) {
		for(neuron_idx=0; neuron_idx<18; neuron_idx++) {
			for(i=0; i<IMG_ROWS; i++) {
				for(j=0; j<IMG_COLS; j++) {
					weight[t*18+neuron_idx][i][j] = mix[t][j] >> 2;
					next_out = ((out[t][j] >> 15) ^ (out[t][j] >> 13) ^ (out[t][j] >> 12) ^ (out[t][j] >> 10)) & 0x0001;
					out[t][j] = (out[t][j] << 1) | next_out;
					mix[t][j] = mixBits(out[t][j]);
				}
			}
		}
	}
#endif

	// Neuron reset
	for(i=0; i<N_EXC; i++) {
		initLIF(&exc_neuron[i]);
	}
	
	for(i=0; i<4; i++) {
		out_ipt[i] = (i+1)*10000;
		mix_ipt[i] = mixBits(out_ipt[i]);
	}


	// Read MNIST data from CSV file
	readMNISTData(filename, mnist_data);
	clock_gettime(CLOCK_MONOTONIC, &begin);
	buf = begin;
	for(n=0; n<TRAIN; n++) {
		max = 0;
		up = 0;
		for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
			post_spike_cnt[neuron_idx] = 0;
		}
		for(t=0; t<800; t++) {
#ifdef CUT	
			// Input layer
			for(i=2; i<26; i++) {
				for(j=0; j<6; j++) {
					for(k=0; k<4; k++) {
						if((mnist_data[n].pixels[i*28 + j*4 + k + 2] << 2) > mix_ipt[k]) {
							pre_spike[i-2][j*4 + k] = 1;
							x1[i-2][j*4 + k] = 0xffff;
						} else {
							pre_spike[i-2][j*4 + k] = 0;
							x1[i-2][j*4 + k] -= x1[i-2][j*4 + k] >> (1 + X_TAU);
						}
						next_out = ((out_ipt[k] >> 15) ^ (out_ipt[k] >> 13) ^ (out_ipt[k] >> 12) ^ (out_ipt[k] >> 10)) & 0x0001;
						out_ipt[k] = (out_ipt[k] << 1) | next_out;
						mix_ipt[k] = mixBits(out_ipt[k]);
#ifdef PRINT
						fprintf(f_input, "%d, ", pre_spike[i-2][j*4 + k]);
						fprintf(f_x, "%d, ", x1[i-2][j*4 + k]);
#endif
					}
				}
			}
#ifdef PRINT
			fprintf(f_input, "\n");
			fprintf(f_x, "\n");
#endif
#else	
			for(i=0; i<28; i++) {
				for(j=0; j<7; j++) {
					for(k=0; k<4; k++) {
						if((mnist_data[n].pixels[i*28 + j*4 + k] << 2) > mix[k]) {
							pre_spike[i][j*4 + k] = 1;
							x1[i][j*4 + k] = 0xffff;
						} else {
							pre_spike[i][j*4 + k] = 0;
							x1[i][j*4 + k] -= x1[i][j*4 + k] >> (1 + X_TAU);
						}
						next_out = ((out[k] >> 15) ^ (out[k] >> 13) ^ (out[k] >> 12) ^ (out[k] >> 10)) & 0x0001;
						out[k] = (out[k] << 1) | next_out;
						mix[k] = mixBits(out[k]);
					}
				}
			}
#endif	
			inh_current = 0;
			// Excitatory neuron
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				exc_current = 0;
				
				// synaptic accumulation
				for(i=0; i<IMG_ROWS; i++) 
					for(j=0; j<IMG_COLS; j++) 
						exc_current += pre_spike[i][j] ? weight[neuron_idx][i][j] : 0;  
				
				updateExcNeuron(&exc_neuron[neuron_idx], exc_current, inh_current_buf, 0);
				post_spike[neuron_idx] = exc_neuron[neuron_idx].spike;

				// membrane update & spike check
				y2_buf[neuron_idx] = y2[neuron_idx];
				if(post_spike[neuron_idx]) {
					y1[neuron_idx] = 0xffff;
					y2[neuron_idx] = 0xffff;
					post_spike_cnt[neuron_idx]++;
					inh_current++;
				} else {
					y1[neuron_idx] -= y1[neuron_idx] >> (1 + Y1_TAU);
					y2[neuron_idx] -= y2[neuron_idx] >> (1 + Y2_TAU);
				}
#ifdef PRINT
				fprintf(f_output, "%d, ", exc_neuron[neuron_idx].spike);
				fprintf(f_mem, "%d, ", exc_neuron[neuron_idx].v);
				fprintf(f_vt, "%d, ", exc_neuron[neuron_idx].thresh);
				fprintf(f_inh, "%d, ", exc_neuron[neuron_idx].inh_g);
				fprintf(f_exc, "%d, ", exc_neuron[neuron_idx].exc_g);
				fprintf(f_y1, "%d, ", y1[neuron_idx]);
				fprintf(f_y2_buf, "%d, ", y2_buf[neuron_idx]);
				fprintf(f_acc, "%d, ", exc_current);
#endif
			}
#ifdef PRINT
			fprintf(f_output, "\n");
			fprintf(f_mem, "\n");
			fprintf(f_vt, "\n");
			fprintf(f_inh, "\n");
			fprintf(f_exc, "\n");
			fprintf(f_y1, "\n");
			fprintf(f_y2_buf, "\n");
			fprintf(f_acc, "\n");
#endif
			if(inh_current == 0) inh_current_buf = 0;
			else if(inh_current == 1) inh_current_buf = INH_WEIGHT;
			else inh_current_buf = CONDUCTANCE_MAX;

			// STDP
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				for(i=0; i<IMG_ROWS; i++) {
					for(j=0; j<IMG_COLS; j++) {
						delta = 0;
						if(pre_spike[i][j] == 1) 
							delta = - (y1[neuron_idx] >> ETA_PRE);  
						if(post_spike[neuron_idx] == 1) {
							delta += (x1[i][j] * y2_buf[neuron_idx]) >> (16 + ETA_POST);
						}
						if((t & 0x000000000000007f) == 126) {
							delta -= 1;
						}
						weight[neuron_idx][i][j] += delta; 
						if(weight[neuron_idx][i][j] < 0)
							weight[neuron_idx][i][j] = 0;
						else if(weight[neuron_idx][i][j] > WEIGHT_MAX)
							weight[neuron_idx][i][j] = WEIGHT_MAX;
					}
				}
			}
		} 
		/*
		for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) 
			if(max < post_spike_cnt[neuron_idx])
				max = post_spike_cnt[neuron_idx];
		
		while((max < 6) && (up < 20)) {
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				post_spike_cnt[neuron_idx] = 0;
			}
			max = 0;
			up++;
			for(t=0; t<800; t++) {
				
				// Input layer
				for(i=2; i<26; i++) {
					for(j=2; j<26; j++) {
						if((mnist_data[n].pixels[i*28 + j] << (3 + (up>>3))) > mix) {
							pre_spike[i-2][j-2] = 1;
							x1[i-2][j-2] = 0xffff;
						} else {
							pre_spike[i-2][j-2] = 0;
							x1[i-2][j-2] -= x1[i-2][j-2] >> (1 + X_TAU);
						}
						next_out = ((out >> 15) ^ (out >> 13) ^ (out >> 12) ^ (out >> 10)) & 0x0001;
						out = (out << 1) | next_out;
						mix = mixBits(out);
					}
				}
		
				// Excitatory neuron
				for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
					inh_current = 0;
					exc_current = 0;
					
					// synaptic accumulation
					for(i=0; i<IMG_ROWS; i++) 
						for(j=0; j<IMG_COLS; j++) 
							exc_current += pre_spike[i][j] ? weight[neuron_idx][i][j] : 0;  
					
					for(i=0; i<N_INH; i++) 
						if(i!=neuron_idx) 
							inh_current += inh_spike[i] ? INH_WEIGHT : 0;
	
					updateExcNeuron(&exc_neuron[neuron_idx], exc_current, inh_current, 0);
					post_spike[neuron_idx] = exc_neuron[neuron_idx].spike;
	
					// membrane update & spike check
					y2_buf[neuron_idx] = y2[neuron_idx];
					if(post_spike[neuron_idx]) {
						y1[neuron_idx] = 0xffff;
						y2[neuron_idx] = 0xffff;
						post_spike_cnt[neuron_idx]++;
					} else {
						y1[neuron_idx] -= y1[neuron_idx] >> (1 + Y1_TAU);
						y2[neuron_idx] -= y2[neuron_idx] >> (1 + Y2_TAU);
					}
				}
		
				for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
					inh_spike[neuron_idx] = post_spike[neuron_idx];
				}

				// STDP
				for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
					for(i=0; i<IMG_ROWS; i++) {
						for(j=0; j<IMG_COLS; j++) {
							delta = 0;
							if(pre_spike[i][j] == 1) 
								delta = - (y1[neuron_idx] >> ETA_PRE);  
							if(post_spike[neuron_idx] == 1) {
								delta += (x1[i][j] * y2_buf[neuron_idx]) >> (16 + ETA_POST);
							}
							weight[neuron_idx][i][j] += delta; 
							if(weight[neuron_idx][i][j] < 0)
								weight[neuron_idx][i][j] = 0;
							else if(weight[neuron_idx][i][j] > WEIGHT_MAX)
								weight[neuron_idx][i][j] = WEIGHT_MAX;
						}
					}
				}
			}	
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				if(max < post_spike_cnt[neuron_idx])
					max = post_spike_cnt[neuron_idx];
			}
		} */
		for(t=0; t<500; t++) {
#ifdef CUT	
			// Input layer
			for(i=2; i<26; i++) {
				for(j=2; j<26; j++) {
					pre_spike[i-2][j-2] = 0;
					x1[i-2][j-2] -= x1[i-2][j-2] >> (1 + X_TAU);
#ifdef PRINT
					fprintf(f_input, "%d, ", pre_spike[i-2][j-2]);
					fprintf(f_x, "%d, ", x1[i-2][j-2]);
#endif
				}
			}
#ifdef PRINT
			fprintf(f_input, "\n");
			fprintf(f_x, "\n");
#endif
#else	
			// Input layer
			for(i=0; i<28; i++) {
				for(j=0; j<28; j++) {
					pre_spike[i][j] = 0;
					x1[i][j] -= x1[i][j] >> (1 + X_TAU);
				}
			}
#endif	
			// Excitatory neuron
			// Excitatory neuron
			inh_current = 0;
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				exc_current = 0;
				
				updateExcNeuron(&exc_neuron[neuron_idx], exc_current, inh_current_buf, 1);
				post_spike[neuron_idx] = exc_neuron[neuron_idx].spike;
				
				// membrane update & spike check
				y2_buf[neuron_idx] = y2[neuron_idx];
				if(post_spike[neuron_idx]) {
					y1[neuron_idx] = 0xffff;
					y2[neuron_idx] = 0xffff;
					post_spike_cnt[neuron_idx]++;
					inh_current++;
				} else {
					y1[neuron_idx] -= y1[neuron_idx] >> (1 + Y1_TAU);
					y2[neuron_idx] -= y2[neuron_idx] >> (1 + Y2_TAU);
				}
#ifdef PRINT
				fprintf(f_output, "%d, ", exc_neuron[neuron_idx].spike);
				fprintf(f_mem, "%d, ", exc_neuron[neuron_idx].v);
				fprintf(f_vt, "%d, ", exc_neuron[neuron_idx].thresh);
				fprintf(f_inh, "%d, ", exc_neuron[neuron_idx].inh_g);
				fprintf(f_exc, "%d, ", exc_neuron[neuron_idx].exc_g);
				fprintf(f_y1, "%d, ", y1[neuron_idx]);
				fprintf(f_y2_buf, "%d, ", y2_buf[neuron_idx]);
				fprintf(f_acc, "%d, ", 0);
#endif
			}
#ifdef PRINT
			fprintf(f_output, "\n");
			fprintf(f_mem, "\n");
			fprintf(f_vt, "\n");
			fprintf(f_inh, "\n");
			fprintf(f_exc, "\n");
			fprintf(f_y1, "\n");
			fprintf(f_y2_buf, "\n");
			fprintf(f_acc, "\n");
#endif
			if(inh_current == 0) inh_current_buf = 0;
			else if(inh_current == 1) inh_current_buf = INH_WEIGHT;
			else inh_current_buf = CONDUCTANCE_MAX;
		
			// STDP
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				for(i=0; i<IMG_ROWS; i++) {
					for(j=0; j<IMG_COLS; j++) {
						delta = 0;
						if(pre_spike[i][j] == 1) 
							delta = - (y1[neuron_idx] >> ETA_PRE);  
						if(post_spike[neuron_idx] == 1) {
							delta += (x1[i][j] * y2_buf[neuron_idx]) >> (16 + ETA_POST);
						}
						weight[neuron_idx][i][j] += delta;
						if(weight[neuron_idx][i][j] < 0)
							weight[neuron_idx][i][j] = 0;
						else if(weight[neuron_idx][i][j] > WEIGHT_MAX)
							weight[neuron_idx][i][j] = WEIGHT_MAX;
					}
				}
			}
		}
		max = 0;
		idx = 0;
		for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
			if(max < post_spike_cnt[neuron_idx]) {
				max = post_spike_cnt[neuron_idx];
				idx = neuron_idx;
			}
		}
#ifdef PRINT
		printf("%d!!\n", idx);
#endif
		if(n > (TRAIN - (TRAIN >> 2))) {
			digit[idx][mnist_data[n].label]++;
		}
		
		if(n%10==9) {
			clock_gettime(CLOCK_MONOTONIC, &end);
			printf("[%d/%d] %.2f percent  10 Image taken: %lf [sec], total time: %lf [sec]\n", n+1, TRAIN, ((float)(n+1))/TRAIN*100,(end.tv_sec - buf.tv_sec) + (end.tv_nsec - buf.tv_nsec) / 1000000000.0, (end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
			buf = end;
		}
	}
	for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
		fprintf(exc_thresh, "%lld\n", exc_neuron[neuron_idx].thresh);
		for(i=0; i<IMG_ROWS; i++) 
			for(j=0; j<IMG_COLS; j++) 
				fprintf(learned, "%lld\n", weight[neuron_idx][i][j]);
	}
	
	for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
		max = 0;
		idx = 0;
		for(i=0; i<10; i++) {
			if(max < digit[neuron_idx][i]) {
				max = digit[neuron_idx][i];
				idx = i;
			}
		}
		fprintf(class, "%d\n", idx);
	}

	free(mnist_data);
	fclose(learned);
	fclose(exc_thresh);
	fclose(class);
	fclose(f_init);
#ifdef PRINT
	fclose(f_output);
	fclose(f_mem);
	fclose(f_vt);
	fclose(f_inh);
	fclose(f_exc);
	fclose(f_y1);
	fclose(f_y2_buf);
	fclose(f_acc);
#endif

	return 0;
}

// Function to read MNIST data from CSV file
void readMNISTData(const char* filename, MNIST* data) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    char line[MAX_LINE_LENGTH];

    // Read and discard the header line
    fgets(line, sizeof(line), file);

    // Read data rows
    for (int i = 0; i < NUM_ROWS; ++i) {
        fgets(line, sizeof(line), file);
        char* token = strtok(line, ",");
        data[i].label = atoi(token);

        // Read pixel values
        for (int j = 0; j < 28 * 28; ++j) {
            token = strtok(NULL, ",");
            data[i].pixels[j] = (unsigned char)atoi(token);
        }
    }

    fclose(file);
}

void initLIF(LIF *neuron) {
    neuron->v = V_REST;
    neuron->spike = 0;
    neuron->exc_g= 0;
    neuron->inh_g = 0;
    neuron->refrac = 0;
    neuron->refrac_check = 0;
    neuron->refrac_check = 0;
    neuron->thresh = THRESH_INIT;
}

void updateExcNeuron(LIF *neuron, long long exc_current, long long inh_current, int rest) {
	long long current;
	if(!neuron->refrac_check) {
		neuron->exc_g += exc_current - (neuron->exc_g >> (1 + TAU_EXC));
		neuron->inh_g += inh_current - (neuron->inh_g >> (1 + TAU_INH));
		if(neuron->inh_g > CONDUCTANCE_MAX)
			neuron->inh_g = CONDUCTANCE_MAX;
		current = ((neuron->exc_g*((E_EXC - neuron->v) >> 7)) >> 10) + ((neuron->inh_g*((E_INH - neuron->v) >> 7)) >> 10);
		neuron->v += (((V_REST - neuron->v) >> 1) + current) >> (TAU_EXC_MEMBRANE);
	} else {
		neuron->refrac++;
		if(neuron->refrac > (EXC_REFRACTORY_PERIOD << 1)) {
			neuron->refrac = 0;
			neuron->refrac_check = 0;
		}
	}
	
	if(!rest)
		neuron->thresh += (V_REST - neuron->thresh) >> (1 + TAU_THRESH);

	// Check threshold
    neuron->spike = 0;
    if(neuron->v > neuron->thresh) {
		neuron->thresh += THRESH_ADD;
		neuron->exc_g = 0;
		neuron->inh_g = 0;
	    neuron->v = V_REST;
		neuron->spike = 1;
		neuron->refrac_check = 1;
    }
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
