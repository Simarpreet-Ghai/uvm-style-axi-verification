SIM = results/tb.vvp
IVERILOG = iverilog
VVP = vvp

SOURCES = \
	src/axi_regbank.sv \
	sim/axi_driver.sv \
	sim/axi_monitor.sv \
	sim/scoreboard.sv \
	sim/assertions.sv \
	sim/coverage.sv \
	sim/seq_lib.sv \
	sim/rand_test.sv \
	sim/tb_top.sv

.PHONY: all run regression wave clean

all: $(SIM)

$(SIM): $(SOURCES)
	mkdir -p results
	$(IVERILOG) -g2012 -o $(SIM) $(SOURCES)

run: $(SIM)
	$(VVP) $(SIM) +TEST=all

regression:
	python3 scripts/run_regression.py

wave:
	@echo "Open results/waveform.vcd with GTKWave or another VCD viewer."

clean:
	rm -f results/tb.vvp results/regression_report.txt results/scoreboard_log.csv results/coverage_report.txt results/waveform.vcd
