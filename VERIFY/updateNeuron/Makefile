TB_SOURCE = updateNeuron_tb

all: compile run

compile: $(TB_SOURCE).v
	iverilog -Wimplicit -o $(TB_SOURCE).o $(TB_SOURCE).v

run: $(OBJ_FILE)
	vvp $(TB_SOURCE).o

show:
	gtkwave $(TB_SOURCE).vcd

clean:
	rm -f $(TB_SOURCE).o *vcd

.PHONY: all compile run clean

