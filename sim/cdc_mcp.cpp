#include "Vcdc_mcp.h"

#include "sim_common.h"

// 100 MHz System Clock Rate
const unsigned SYSTEM_CLOCK_RATE = (100 * 1000 * 1000);

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    MainTestBenchDualClock<Vcdc_mcp> tb("cdc_mcp");
    tb.parseArgs(argc, argv);

    tb.signalStart();

    tb.signalDone();

    return 0;
}
