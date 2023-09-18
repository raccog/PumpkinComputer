#include "Vdmi_jtag.h"

#include "sim_common.h"

// 100 MHz System Clock Rate
const unsigned SYSTEM_CLOCK_RATE = (100 * 1000 * 1000);

s_vpi_value vpiGet(const std::string &path, PLI_INT32 valueFormat) {
    std::string handle = "TOP." + path;
    vpiHandle vh = vpi_handle_by_name((PLI_BYTE8*)handle.c_str(), NULL);
    if (!vh) {
        std::string errMsg = "No handle found for " + path;
        vl_fatal(__FILE__, __LINE__, "sim_dmi_jtag", errMsg.c_str());
    }
    s_vpi_value val;
    val.format = valueFormat;
    vpi_get_value(vh, &val);
    return val;
}

#define VPI_GET_INT(path) \
    vpiGet(path, vpiIntVal).value.integer

#define TEST_LOGIC_RESET 0xf

void resetJtag(MainTestBench<Vdmi_jtag> &tb) {
    // After 5 clock ticks with i_tms asserted, the JTAG state should be in
    // Test-Logic Reset.
    tb->i_tms = 1;
    tb.tick(5);
    int current_state = VPI_GET_INT("dmi_jtag.current_state");
    assert(current_state == TEST_LOGIC_RESET);
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

