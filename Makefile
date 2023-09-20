BUILD_DIR ?= build
VCD_DIR ?= vcd
SIMULATOR_ARGS ?=
CC_ARGS ?= -Wall -O2
ifdef DEBUG
	CC_ARGS += -NDEBUG
endif

MODULES := dmi_jtag uart_tx cdc_mcp
EXECUTABLES := $(patsubst %,$(BUILD_DIR)/%_sim,$(MODULES))
VCD_FILES := $(addsuffix .vcd,$(MODULES))
VCD_TARGETS := $(addprefix open-vcd-,$(MODULES))

all: $(EXECUTABLES)
.PHONY: all

book-serve:
	mdbook serve book
.PHONY: book-serve

clean:
	rm -rf $(BUILD_DIR) $(VCD_DIR)
.PHONY: clean

simulate-all: $(EXECUTABLES)
	-mkdir -p $(VCD_DIR)
	for exe in $^; do $$exe $(SIMULATOR_ARGS); done
.PHONY: simulate-all	

simulate-%: $(BUILD_DIR)/%_sim
	-mkdir -p $(VCD_DIR)
	$< $(SIMULATOR_ARGS)
.PHONY: simulate-*

%.vcd: $(BUILD_DIR)/%_sim
	-mkdir -p $(VCD_DIR)
	$< $(SIMULATOR_ARGS)
.PRECIOUS: $(VCD_DIR)/*.vcd

open-vcd-%: $(VCD_DIR)/%.vcd
	gtkwave $< >/dev/null 2>&1 &
.PHONY: open-vcd-*

$(BUILD_DIR)/verilated.o: /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp \
		/usr/share/verilator/include/verilated_vpi.cpp
	-mkdir -p "$(@D)"
	g++ -shared -fPIC -I /usr/share/verilator/include \
		-I /usr/share/verilator/include/vltstd \
		$^ \
		-O2 \
		-o "$@"

$(BUILD_DIR)/%_sim: sim/%.cpp sim/sim_common.h \
	$(BUILD_DIR)/obj_dir/V%__ALL.a $(BUILD_DIR)/verilated.o
	-mkdir -p "$(@D)"
	g++ -I /usr/share/verilator/include \
		-I $(BUILD_DIR)/obj_dir/ \
		-I /usr/share/verilator/include/vltstd \
		-I sim \
		$^ \
		$(CC_ARGS) \
		-o "$@"

$(BUILD_DIR)/obj_dir/V%.mk: rtl/%.sv rtl/%*.sv
	-mkdir -p "$(@D)"
	verilator --Mdir "$(@D)" -Wall --trace -cc $^

$(BUILD_DIR)/obj_dir/V%__ALL.a: $(BUILD_DIR)/obj_dir/V%.mk
	make -f "$(<F)" -C "$(BUILD_DIR)/obj_dir"

