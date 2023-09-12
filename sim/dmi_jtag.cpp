#include "Vdmi_jtag.h"

#include "sim_common.h"

// 100 MHz System Clock Rate
const unsigned SYSTEM_CLOCK_RATE = (100 * 1000 * 1000);

void resetJtag(MainTestBench<Vdmi_jtag> &tb) {
    tb->i_tms = 1;
    tb.tick(5);
    assert(tb->current_state == 0xf);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    MainTestBench<Vdmi_jtag> tb("dmi_jtag");
    tb.parseArgs(argc, argv);

    VPRINTF("Starting test bench for `dmi_jtag`\n");

    // Ensure that holding TMS high for 5 clock cycles will always reset the
    // JTAG module
    resetJtag(tb);

    return 0;
}

