BUILD_DIR ?= build
SIMULATOR_ARGS ?= -v
CC_ARGS ?= -Wall -O2

all: $(BUILD_DIR)/uart_tx
.PHONY: all

book-serve:
	mdbook serve book
.PHONY: book-serve

clean:
	rm -rf $(BUILD_DIR)
.PHONY: clean

simulate-all: simulate-uart_tx
.PHONY: simulate-all	

simulate-uart_tx: $(BUILD_DIR)/uart_tx
	$< $(SIMULATOR_ARGS)
.PHONY: simulate-uart_tx

uart_tx.vcd: $(BUILD_DIR)/uart_tx
	$< $(SIMULATOR_ARGS)

open-vcd-uart_tx: uart_tx.vcd
	gtkwave $<
.PHONY: open-vcd-uart_tx

$(BUILD_DIR)/verilated.o: /usr/share/verilator/include/verilated.cpp \
		/usr/share/verilator/include/verilated_threads.cpp \
		/usr/share/verilator/include/verilated_vcd_c.cpp
	g++ -shared -fPIC -I /usr/share/verilator/include \
		-I /usr/share/verilator/include/vltstd \
		$^ \
		-O2 \
		-o "$@"

$(BUILD_DIR)/uart_tx: sim/uart_tx.cpp sim/sim_common.h \
	$(BUILD_DIR)/obj_dir/Vuart_tx__ALL.a $(BUILD_DIR)/verilated.o
	-mkdir -p "$(@D)"
	g++ -I /usr/share/verilator/include \
		-I $(BUILD_DIR)/obj_dir/ \
		-I /usr/share/verilator/include/vltstd \
		-I sim \
		$^ \
		$(CC_ARGS) \
		-o "$@"

$(BUILD_DIR)/obj_dir/Vuart_tx__ALL.a: rtl/uart_tx.v
	-mkdir -p "$(@D)"
	verilator --Mdir "$(@D)" -Wall --trace -cc "$<"
	make -f Vuart_tx.mk -C "$(BUILD_DIR)/obj_dir"

