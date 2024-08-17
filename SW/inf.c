#include "snn.h"

#define MAX_LINE_LENGTH 10000
#define NUM_ROWS 8900  // MNIST training set size
#define NUM_COLS 785    // 1 label + 28x28 pixels
#define OFFSET 0
#define TEST 10000


int main(void) {

	struct timespec  begin, end, buf;

	int neuron_idx, i, j, k, t, n;

	// LFSR 
	unsigned short out[4]; 
    unsigned short next_out;
    unsigned short mix[4];

	for(i=0; i<4; i++) {
		out[i] = i*1000 + 101;
		mix[i] = mixBits(out[i]);
	}

	// MNIST data
	const char* filename = "../../dataset/mnist_test.csv";
	MNIST *mnist_data = (MNIST*)malloc(NUM_ROWS * sizeof(MNIST));

	// Spike memory
	unsigned char pre_spike[IMG_ROWS][NUM_COLS];
	unsigned char post_spike[N_EXC] = {0,};
	unsigned char post_spike_cnt[N_EXC] = {0,};

	// Excitatory 
	LIF exc_neuron[N_EXC];

	// Weight memory
	long long weight[N_EXC][IMG_ROWS][IMG_COLS];

	// Learned class
	int digit[N_EXC];

	long long inh_current, inh_current_buf, exc_current;
	long long tmp;
	unsigned char max, idx;

	FILE *learned, *exc_thresh, *class, *inf_out;


	// Open the file for writing
	learned = fopen("learn_weight_ref.txt", "r");
	exc_thresh = fopen("exc_threshold_ref.txt", "r");
	inf_out = fopen("inf_out.txt", "w");
	class = fopen("neuron_class_ref.txt", "r");

	// Weight reset
	for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
		for(i=0; i<IMG_ROWS; i++) {
			for(j=0; j<IMG_COLS; j++) {
				fscanf(learned, "%lld", &tmp);
				weight[neuron_idx][i][j] = tmp;
			}
		}
	}

	// Neuron reset
	for(i=0; i<N_EXC; i++) {
		initLIF(&exc_neuron[i]);
		fscanf(exc_thresh, "%lld", &tmp);
		exc_neuron[i].thresh = tmp;
	}

	// Class set
	for(i=0; i<N_EXC; i++)
		fscanf(class, "%d", &digit[i]);

	// Read MNIST data from CSV file
	readMNISTData(filename, mnist_data);
	clock_gettime(CLOCK_MONOTONIC, &begin);
	buf = begin;
	for(n=0; n<TEST; n++) {
		tmp = 0;
		max = 0;
		for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
			post_spike_cnt[neuron_idx] = 0;
		}
		for(t=0; t<800; t++) {
#ifdef CUT
			// Input layer
			for(i=2; i<26; i++) {
				for(j=0; j<6; j++) {
					for(k=0; k<4; k++) {
						if((mnist_data[n].pixels[i*28 + j*4 + k + 2] << 2) > mix[k]) {
							pre_spike[i-2][j*4 + k] = 1;
						} else {
							pre_spike[i-2][j*4 + k] = 0;
						}
						next_out = ((out[k] >> 15) ^ (out[k] >> 13) ^ (out[k] >> 12) ^ (out[k] >> 10)) & 0x0001;
						out[k] = (out[k] << 1) | next_out;
						mix[k] = mixBits(out[k]);
					}
				}
			}
#else 	
			// Input layer
			for(i=0; i<28; i++) {
				for(j=0; j<7; j++) {
					for(k=0; k<4; k++) {
						if((mnist_data[n].pixels[i*28 + j*4 + k] << 2) > mix[k]) {
							pre_spike[i][j*4 + k] = 1;
						} else {
							pre_spike[i][j*4 + k] = 0;
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

				if(post_spike[neuron_idx])  {
					post_spike_cnt[neuron_idx]++;
					inh_current++;
				}
			}
			inh_current_buf = inh_current*INH_WEIGHT;
		}
		for(t=0; t<500; t++) {
#ifdef CUT
			// Input layer
			for(i=2; i<26; i++) {
				for(j=0; j<6; j++) {
					for(k=0; k<4; k++) {
						pre_spike[i-2][j*4 + k] = 0;
					}
				}
			}
#else 	
			// Input layer
			for(i=0; i<28; i++) {
				for(j=0; j<7; j++) {
					for(k=0; k<4; k++) {
						pre_spike[i][j*4 + k] = 0;
					}
				}
			}
#endif
			inh_current = 0;
			// Excitatory neuron
			for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
				exc_current = 0;
				
				updateExcNeuron(&exc_neuron[neuron_idx], exc_current, inh_current_buf, 0);
				post_spike[neuron_idx] = exc_neuron[neuron_idx].spike;

				if(post_spike[neuron_idx]) {
					post_spike_cnt[neuron_idx]++;
					inh_current++;
				}
			}
			inh_current_buf = inh_current*INH_WEIGHT;
		}
		
		idx = 0;
		for(neuron_idx=0; neuron_idx<N_EXC; neuron_idx++) {
			if(max < post_spike_cnt[neuron_idx]) {
				max = post_spike_cnt[neuron_idx];
				idx = neuron_idx;
			}
		}
		fprintf(inf_out, "%d, %d\n", mnist_data[n+OFFSET].label, digit[idx]);
	
		if(n%10==9) {
			clock_gettime(CLOCK_MONOTONIC, &end);
			printf("[%d/%d] %.2f percent  10 Image taken: %lf [sec], total time: %lf [sec]\n", n+1, TEST, ((float)(n+1))/TEST*100,(end.tv_sec - buf.tv_sec) + (end.tv_nsec - buf.tv_nsec) / 1000000000.0, (end.tv_sec - begin.tv_sec) + (end.tv_nsec - begin.tv_nsec) / 1000000000.0);
			buf = end;
		}
	}

	free(mnist_data);
	fclose(learned);
	fclose(exc_thresh);
	fclose(inf_out);
	fclose(class);

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

	// Check threshold
    neuron->spike = 0;
    if(neuron->v > neuron->thresh) {
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
