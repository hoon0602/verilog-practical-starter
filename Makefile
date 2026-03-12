TOP=verilog_practical_starter
BUILD_DIR=build
OUT=$(BUILD_DIR)/$(TOP).out
VCD=$(BUILD_DIR)/$(TOP).vcd

.PHONY: sim wave clean status

sim:
	./run_sim.sh

wave:
	./run_sim.sh --wave

clean:
	rm -rf $(BUILD_DIR)

status:
	git status --short --branch
