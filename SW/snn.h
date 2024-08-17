#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define N_IMG 784
#define N_INPUT 576
#define N_EXC 144
#define N_INH 144

#define CUT

#ifdef CUT
#define IMG_ROWS 24
#define IMG_COLS 24
#else
#define IMG_ROWS 28
#define IMG_COLS 28
#endif

#define INH_WEIGHT 458752
#define WEIGHT_MAX 65535

#define ETA_PRE 10
#define ETA_POST 4

#define X_TAU 3
#define Y1_TAU 3
#define Y2_TAU 4

#define V_REST 5242880				// Membrane rest potential							[mV]
#define THRESH_INIT 5406720			// Initial spike threshold							[mV]
#define INH_THRESH 5898240			// Inhibitory neuron spike threshold				[mV]
#define THRESH_ADD 11240		// Spike threshold									[mV]
#define TAU_THRESH 16		// Spike threshold leaky time constant				[ms]
#define TAU_EXC_MEMBRANE 7		// Membrane leaky time constant						[ms]
#define TAU_EXC 2				// Excitatory synapse channel leaky time constant	[ms]
#define TAU_INH 3				// Excitatory synapse channel leaky time constant	[ms]
#define E_EXC 6881280				// Excitatory synapse channel rest potential		[mV]
#define E_INH 3604480				// Excitatory synapse channel rest potential		[mV]
#define EXC_REFRACTORY_PERIOD 5		// Neuron refractory period							[ms]
#define CONDUCTANCE_MAX 655360
#define DT 0.5				// Time step

// Structure to represent a single MNIST data row
typedef struct {
    unsigned char label;
    unsigned char pixels[28 * 28];
} MNIST;

// LIF neuron structure
typedef struct {
	long long v;		// Membrane potential [mV]
	long long exc_g;	// Excitatory synapse channel conductance	
	long long inh_g;
	long long refrac;
	long long thresh;
	long long refrac_check;
	int spike;
} LIF;

void readMNISTData(const char* filename, MNIST* data);					// read MNIST data from CSV file 
void initLIF(LIF *neuron);												// reset neuron
void updateExcNeuron(LIF *neuron, long long exc_current, long long inh_current, int rest);	// update neuron
void updateInhNeuron(LIF *neuron, long long exc_current);
unsigned short mixBits(unsigned short input);
