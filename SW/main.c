/***************************** Include Files *********************************/

#include "xparameters.h"	/* SDK generated parameters */
#include "xsdps.h"		/* SD device driver */
#include "xil_printf.h"
#include "ff.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include "xil_io.h"
#include "xiltimer.h"
#include <stdio.h>
#include <stdlib.h>
/************************** Constant Definitions *****************************/
#define COUNTS_PER_SECOND          (XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ /2)

#define WRITE 1
#define READ 1
#define AXI_DATA_BYTE 4

#define IDLE 1
#define BUSY 1 << 1
#define DONE 1 << 2

#define CTRL_REG 0
#define STATUS_REG 1
#define MEM0_ADDR_REG 2
#define MEM0_DATA_REG 3
#define RESULT_REG 4

#define MEM_DEPTH 144

#define N_EXC 144

//#define PRINT


/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Variable Definitions *****************************/
static FIL fil;		/* File object */
static DIR dir;		/* File object */
static FATFS fatfs;
/*
 * To test logical drive 0, FileName should be "0:/<File name>" or
 * "<file_name>". For logical drive 1, FileName should be "1:/<file_name>"
 */
static char TrainFileName[32] = "TRAIN.BIN";
static char TestFileName[32] = "TEST.BIN";
static char *SD_File;

#define NUM_IMG 40000

/**************************** Main Function Start ****************************/
int main(void)
{
	UINT NumBytesRead;
	int i, j, n;
	int read_data;
	int max, idx;
	int inst;
	XTime tInit, tStart, tEnd, tBuf;
	FRESULT Res;
	unsigned int img[145];
	int response[N_EXC][10] = {0,};
	int label[N_EXC] = {0,};
	double o, x;
	double hw_runtime;
	TCHAR *Path = "0:/";

	// SD Card Set
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		printf("f_mount failed\n");
		return XST_FAILURE;
	}
	FILINFO fileInfo;

	f_opendir(&dir, Path);
	while (1) {
	    Res = f_readdir(&dir, &fileInfo);
	    if (Res != FR_OK || fileInfo.fname[0] == '\0') break;  // End of directory or error

	    printf("%s\n", fileInfo.fname);
	}

	// Start
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg

	// Check IDLE
	do{
    	read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    } while( (read_data & IDLE) != IDLE );
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x80000000)); // init
    do{
    	read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    } while( (read_data & DONE) != DONE );

    printf("/********************************** Set Done **********************************/\n");
init:
    do {
    printf("Enter value\n0: Reset\n1: Learning Start\n2: Test Start\n3: Finish\n");
    scanf("%d", &inst);
    } while((inst != 0) && (inst != 1) && (inst != 2) && (inst != 3));

    if (inst == 0) goto reset;
    else if (inst == 1) goto learn;
    else if(inst == 2) goto test;
    else if(inst == 3) goto finish;

learn:
	SD_File = (char *)TrainFileName;

	Res = f_open(&fil, SD_File, FA_OPEN_EXISTING | FA_OPEN_ALWAYS | FA_READ);
	if (Res) {
		printf("f_open failed [%d] \n", Res);
		return XST_FAILURE;
	}

	Res = f_lseek(&fil, 0);
	if (Res) {
		printf("f_lseek failed\n");
		return XST_FAILURE;
	}

	for(i=0; i<N_EXC; i++)
		for(j=0; j<10; j++)
			response[i][j] = 0;

	do {
		printf("\nEnter Number of images to learn: (Up to 40000)\n");
		scanf("%d", &inst);
	} while( !((inst > 0) && (inst <= 40000)) );
	printf("/********************************** Learning Start **********************************/\n");
	hw_runtime = 0;
	XTime_GetTime(&tInit);
	tBuf = tInit;
	for(n=0; n<inst; n++) {
#ifdef PRINT
		XTime_GetTime(&tStart);
		// MNIST Image Read from SD Card
		Res = f_read(&fil, img, sizeof(unsigned int)*145, &NumBytesRead);
		if (Res) {
			printf("[%d] f_read [%d] failed\n", i, Res);
			return XST_FAILURE;
		}
		// MNIST Image Write to BRAM
		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
		for(i=0; i<MEM_DEPTH; i++){
    		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), img[i+1]);
		}
		XTime_GetTime(&tEnd);
		printf("MNIST image write took %llu clock cycles.\n", 2*(tEnd - tStart));
    	printf("MNIST image write took %.2f us.\n", 1.0 * (tEnd - tStart) * 0.003);
		hw_runtime +=  1.0 * (tEnd - tStart) * 0.003;


		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x40000000)); // Learn
		XTime_GetTime(&tStart);
		// wait done
    	do{
    		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    	} while( (read_data & DONE) != DONE );
    	XTime_GetTime(&tEnd);
		// Image [n] learning finished
		printf("%d image learning took %llu clock cycles.\n", n, 2*(tEnd - tStart));
    	printf("%d image learning took %.2f us.\n", n, 1.0 * (tEnd - tStart) * 0.003);

		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (RESULT_REG*AXI_DATA_BYTE));
		printf("Iteration: [%d], label : %d, Winner neuron index : %d\n", n, img[0], read_data);

		hw_runtime +=  1.0 * (tEnd - tStart) * 0.003;
		if(n > ((inst*3) >> 2)) {
			response[read_data][img[0]]++;
		}
		if(n%10 == 9) {
			printf("[%d/%d] %.2f percent total time: %lf [sec]\n\n\n\n\n\n", n+1, inst, 100*(double)(n+1)/(double)inst, hw_runtime/1000000);
		}
		printf("/*****************************************************************************/\n\n\n\n\n");
		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg
#else
				// MNIST Image Read from SD Card
				Res = f_read(&fil, img, sizeof(unsigned int)*145, &NumBytesRead);
				if (Res) {
					printf("[%d] f_read [%d] failed\n", i, Res);
					return XST_FAILURE;
				}
				// MNIST Image Write to BRAM
				Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
				for(i=0; i<MEM_DEPTH; i++){
		    		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), img[i+1]);
				}

				Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x40000000)); // Learn
				// wait done
		    	do{
		    		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
		    	} while( (read_data & DONE) != DONE );

				if(n > ((inst*3) >> 2)) {
					read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (RESULT_REG*AXI_DATA_BYTE));
					response[read_data][img[0]]++;
				}
				Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg

				if(n%10 == 9) {
					XTime_GetTime(&tEnd);
					printf("[%d/%d] %.2f percent 10 Image taken: %lf [sec], total time: %lf [sec]\n",
							n+1, inst, 100*(double)(n+1)/(double)inst, (tEnd - tBuf) * 0.000000003,
							(tEnd - tInit) * 0.000000003);
					tBuf = tEnd;
				}
#endif
	}

	/********************************* Neuron Labeling *********************************/
	for(i=0; i<N_EXC; i++) {
		max = 0;
		idx = 0;
		for(j=0; j<10; j++) {
			if(max < response[i][j]) {
				max = response[i][j];
				idx = j;
			}
		}
		label[i] = idx;
	}

	Res = f_close(&fil);
	if (Res) {
			printf("f_close failed\n");
			return XST_FAILURE;
	}

    printf("/********************************** Learning Done **********************************/\n");
    goto init;

test:
	SD_File = (char *)TestFileName;

	Res = f_open(&fil, SD_File, FA_OPEN_EXISTING | FA_OPEN_ALWAYS | FA_READ);
	if (Res) {
		printf("f_open failed [%d] \n", Res);
		return XST_FAILURE;
	}


	Res = f_lseek(&fil, 0);
	if (Res) {
		printf("f_lseek failed\n");
		return XST_FAILURE;
	}

	o = 0;
	x = 0;
	do {
		printf("\nEnter Number of images to test: (Up to 10000)\n");
		scanf("%d", &inst);
	} while ( !((inst > 0) && (inst <= 10000)) );
	printf("/*********************************** Test Start ***********************************/\n");
	hw_runtime = 0;
	XTime_GetTime(&tInit);
	tBuf = tInit;
	for(n=0; n<inst; n++) {
#ifdef PRINT
		XTime_GetTime(&tStart);
		// MNIST Image Read from SD Card
		Res = f_read(&fil, img, sizeof(unsigned int)*145, &NumBytesRead);
		if (Res) {
			printf("[%d] f_read [%d] failed\n", i, Res);
			return XST_FAILURE;
		}
		// MNIST Image Write to BRAM
		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
		for(i=0; i<MEM_DEPTH; i++){
    		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), img[i+1]);
		}
		XTime_GetTime(&tEnd);
		printf("MNIST image write took %llu clock cycles.\n", 2*(tEnd - tStart));
    	printf("MNIST image write took %.2f us.\n", 1.0 * (tEnd - tStart) * 0.003);
		hw_runtime +=  1.0 * (tEnd - tStart) * 0.003;

		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x20000000)); // Inference
		XTime_GetTime(&tStart);
		// wait done
    	do{
    		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    	} while( (read_data & DONE) != DONE );
    	XTime_GetTime(&tEnd);
		// Image [n] learning finished
		printf("%d image inference took %llu clock cycles.\n", n, 2*(tEnd - tStart));
    	printf("%d image inference took %.2f us.\n", n, 1.0 * (tEnd - tStart) * 0.003);
		hw_runtime +=  1.0 * (tEnd - tStart) * 0.003;

		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (RESULT_REG*AXI_DATA_BYTE));
		printf("Iteration: [%d], label : %d, Inference : %d\n", n, img[0], label[read_data]);
		if(img[0] == label[read_data]) {
			o++;
		} else {
			x++;
		}
		printf("Correct : %.lf, Incorrect : %.lf, Accuracy : %.3lf\n\n", o, x, o/(o+x));
		if(n%10 == 9) {
			printf("[%d/%d] %.2f percent total time: %lf [sec]\n", n+1, inst, (double)(n+1)/(double)inst, hw_runtime/1000000);
		}
		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg
#else
		// MNIST Image Read from SD Card
		Res = f_read(&fil, img, sizeof(unsigned int)*145, &NumBytesRead);
		if (Res) {
			printf("[%d] f_read [%d] failed\n", i, Res);
			return XST_FAILURE;
		}
		// MNIST Image Write to BRAM
		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_ADDR_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // Clear
		for(i=0; i<MEM_DEPTH; i++){
    		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (MEM0_DATA_REG*AXI_DATA_BYTE), img[i+1]);
		}

		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x20000000)); // Inference
		// wait done
    	do{
    		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    	} while( (read_data & DONE) != DONE );

		read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (RESULT_REG*AXI_DATA_BYTE));
		if(img[0] == label[read_data]) {
			o++;
		} else {
			x++;
		}

		Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg
		if(n%10 == 9) {
			XTime_GetTime(&tEnd);
			printf("[%d/%d] %.2f percent 10 Image taken: %lf [sec], total time: %lf [sec]\n",
					n+1, inst, 100*(double)(n+1)/(double)inst, (tEnd - tBuf) * 0.000000003,
					(tEnd - tInit) * 0.000000003);
			tBuf = tEnd;
		}
#endif
	}
	printf("/*********************************** Test Done ***********************************/\n");
	printf("Correct : %.lf, Incorrect : %.lf, Accuracy : %.4lf\n\n", o, x, o/(o+x));

	Res = f_close(&fil);
	if (Res) {
			printf("f_close failed\n");
			return XST_FAILURE;
	}

	goto init;

reset:
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x80000000)); // init
	Xil_Out32((XPAR_HOJUN_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000)); // init core ctrl reg
    do{
    	read_data = Xil_In32((XPAR_HOJUN_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
    } while( (read_data & DONE) != DONE );
    goto init;


finish:
	printf("/*********************************** Done ***********************************/\n");



	return XST_SUCCESS;

}

