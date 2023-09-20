#include "Vdmi_jtag.h"
#include <iostream>

#define I_CLK i_tck
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

const unsigned IR_WIDTH = 5;

enum JtagState {
    EXIT2_DR = 0,
    EXIT1_DR,
    SHIFT_DR,
    PAUSE_DR,
    SELECT_IR_SCAN,
    UPDATE_DR,
    CAPTURE_DR,
    SELECT_DR_SCAN,
    EXIT2_IR,
    EXIT1_IR,
    SHIFT_IR,
    PAUSE_IR,
    RUN_TEST_IDLE,
    UPDATE_IR,
    CAPTURE_IR,
    TEST_LOGIC_RESET
};

enum JtagInstruction {
    BYPASS0 = 0x00,
    IDCODE = 0x01,
    DTMCS = 0x10,
    DMI = 0x11,
    BYPASS1 = 0x1f
};

struct JtagIdcode {
    unsigned _reserved : 1;
    unsigned manufid : 11;
    unsigned partnumber : 16;
    unsigned version : 4;
} __attribute__ ((__packed__));

const JtagIdcode IDCODE_RESET = {
    ._reserved = 1,
    .manufid = 0x7ff,
    .partnumber = 0xffff,
    .version = 0xf
};

JtagState jtagCurrentState() {
    return (JtagState)VPI_GET_INT("dmi_jtag.current_state");
}

JtagInstruction jtagCurrentInstruction() {
    return (JtagInstruction)VPI_GET_INT("dmi_jtag.current_instruction");
}

JtagInstruction jtagInstructionReg() {
    return (JtagInstruction)VPI_GET_INT("dmi_jtag.reg_instruction");
}

void resetJtag(MainTestBench<Vdmi_jtag> &tb) {
    // After 5 clock ticks with i_tms asserted, the JTAG state should be in
    // Test-Logic Reset.
    tb->i_tms = 1;
    tb.ticks(5);
    assert(jtagCurrentState() == TEST_LOGIC_RESET);
}

unsigned shiftData(MainTestBench<Vdmi_jtag> &tb, unsigned width, unsigned dataIn = 0, bool exit = false) {
    unsigned dataOut = 0;
    tb->i_tms = 0;
    for (unsigned i = 0; i < width; ++i) {
        // Shift bit out
        dataOut <<= 1;
        dataOut |= tb->o_td;

        // Shift bit in
        tb->i_td = dataIn & 1;
        dataIn >>= 1;

        // Move to next state
        if (i == width - 1 && exit) {
            tb->i_tms = 1;
        }
        tb.tick();
    }
    return dataOut;
}

void loadInstruction(MainTestBench<Vdmi_jtag> &tb, JtagInstruction instruction) {
    // JTAG must be in the Select-IR-Scan state for this function
    assert(jtagCurrentState() == SELECT_IR_SCAN);

    // Move to Shift-IR
    tb->i_tms = 0;
    tb.ticks(2);

    // Assert that instruction register resets to fixed pattern
    assert((unsigned)jtagInstructionReg() == IDCODE);

    // Shift in instruction
    shiftData(tb, IR_WIDTH, static_cast<unsigned>(instruction), true);

    // Move to Update-IR
    tb.tick();
    assert(jtagCurrentState() == UPDATE_IR);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    MainTestBench<Vdmi_jtag> tb("dmi_jtag");
    tb.parseArgs(argc, argv);

    tb.signalStart();

    // Ensure that holding TMS high for 5 clock cycles will always reset the
    // JTAG module
    resetJtag(tb);

    // Move to Select-IR-Scan to load instruction
    tb->i_tms = 0;
    tb.tick();
    tb->i_tms = 1;
    tb.ticks(2);
    assert(jtagCurrentState() == SELECT_IR_SCAN);

    // Load IDCODE instruction
    loadInstruction(tb, IDCODE);

    // Move to Select-DR-Scan
    tb->i_tms = 1;
    tb.tick();
    assert(jtagCurrentState() == SELECT_DR_SCAN);

    // Assert current instruction updated to IDCODE
    assert(jtagCurrentInstruction() == IDCODE);

    // Move to Shift-DR
    tb->i_tms = 0;
    tb.ticks(2);
    assert(jtagCurrentState() == SHIFT_DR);

    // Shift in IDCODE register
    JtagIdcode idcode;
    idcode._reserved = shiftData(tb, 1);
    assert(idcode._reserved == IDCODE_RESET._reserved);
    unsigned manufid = shiftData(tb, 11);
    idcode.manufid = manufid;
    assert(manufid == IDCODE_RESET.manufid);
    unsigned partnumber = shiftData(tb, 16);
    idcode.partnumber = partnumber;
    assert(partnumber == IDCODE_RESET.partnumber);
    unsigned version = shiftData(tb, 4, 0, true);
    idcode.version = version;
    assert(version == IDCODE_RESET.version);

    // Move to Run-Test/Idle
    tb->i_tms = 1;
    tb.tick();
    tb->i_tms = 0;
    tb.tick();
    assert(jtagCurrentState() == RUN_TEST_IDLE);

    tb.signalDone();

    return 0;
}

