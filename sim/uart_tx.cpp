#include <cassert>
#include <cstdio>
#include <cstdlib>

#include "Vuart_tx.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// 100 MHz System Clock Rate
const unsigned SYSTEM_CLOCK_RATE = (100 * 1000 * 1000);
// 9600 UART Baud Rate
const unsigned BAUD_RATE = 9600;
const unsigned CYCLES_PER_BAUD = 100000000 / BAUD_RATE;

bool verbose = false;

#define VPRINTF(...) \
    if (verbose) printf(__VA_ARGS__)

void parseArgs(int argc, char **argv) {
    // Check for verbose command argument
    if (argc > 1) {
        for (int i = 1; i < argc; ++i) {
            if (strcmp(argv[i], "-v") == 0) {
                verbose = true;
            }
        }
    }
}

// TODO: Move these functions into a class
void tick(unsigned tick_count, Vuart_tx *tb, VerilatedVcdC *tfp) {
    tb->eval();
    if (tfp)
        tfp->dump(tick_count * 10 - 2);
    tb->i_clk = 1;
    tb->eval();
    if (tfp)
        tfp->dump(tick_count * 10);
    tb->i_clk = 0;
    tb->eval();
    if (tfp) {
        tfp->dump(tick_count * 10 + 5);
        tfp->flush();
    }
}

void tickBaud(unsigned &tick_counter, Vuart_tx *tb, VerilatedVcdC *tfp,
        unsigned baud_ticks) {
    for (unsigned i = 0; i < baud_ticks; ++i) {
        for (unsigned k = 0; k < CYCLES_PER_BAUD; ++k) {
            tick(tick_counter, tb, tfp);
            tick_counter += 1;
        }
    }
}

void test_transmit(unsigned &tick_counter, Vuart_tx *tb, VerilatedVcdC *tfp,
        uint8_t data, bool continuous) {
    tb->i_data = data;
    tb->i_start = 1;

    // Start bit (takes 2 baud ticks to register change from [i_start] and move out of
    // idle state)
    if (!tb->o_busy) {
        tickBaud(tick_counter, tb, tfp, 1);
        VPRINTF("IDLE TX: %d (expected: 1)\n", tb->o_tx);
        assert(tb->o_tx == 1);
    }
    tickBaud(tick_counter, tb, tfp, 1);
    VPRINTF("START TX: %d (expected: 0)\n", tb->o_tx);
    assert(tb->o_busy == 1);
    assert(tb->o_tx == 0);

    if (!continuous) {
        tb->i_start = 0;
    }

    // Data bits
    for (int i = 0; i < 8; ++i) {
        tickBaud(tick_counter, tb, tfp, 1);
        uint8_t expected_tx = (data >> i) & 1;
        VPRINTF("DATA TX: %d (expected: %d)\n", tb->o_tx, expected_tx);
        assert(tb->o_busy == 1);
        assert(tb->o_tx == expected_tx);
    }

    // Stop bit
    tickBaud(tick_counter, tb, tfp, 1);
    VPRINTF("STOP TX: %d (expected: 1)\n", tb->o_tx);
    assert(tb->o_busy == 1);
    assert(tb->o_tx == 1);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    parseArgs(argc, argv);

    Vuart_tx *tb = new Vuart_tx;

    VPRINTF("Starting test bench\n");

    unsigned tick_counter = 1;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    tb->trace(tfp, 99);
    // TODO: Environment variable or command argument for vcd dir
    tfp->open("uart_tx.vcd");

    // Ensure reset can be held for a few baud cycles
    tb->i_rst = 1;
    tickBaud(tick_counter, tb, tfp, 1);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);

    tickBaud(tick_counter, tb, tfp, 10);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);

    // Ensure transmitter stays idle when out of reset
    tb->i_rst = 0;
    tb->i_start = 0;
    tickBaud(tick_counter, tb, tfp, 1);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);

    tickBaud(tick_counter, tb, tfp, 10);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);

    // Ensure transmitter can transmit a valid data byte
    const uint8_t BYTE0 = 0xab;
    test_transmit(tick_counter, tb, tfp, BYTE0, false);

    // Ensure transmitter goes back to idle state
    tickBaud(tick_counter, tb, tfp, 1);
    VPRINTF("IDLE TX: %d (expected: 1)\n", tb->o_tx);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);

    // Ensure transmitter can send continuous bytes
    const uint8_t BYTES0[] = {0xcd, 0xef, 0x55, 0x00};
    for (int i = 0; i < sizeof(BYTES0); ++i) {
        test_transmit(tick_counter, tb, tfp, BYTES0[i], i != sizeof(BYTES0) - 1);
    }

    // Ensure transmitter goes back to idle state
    tickBaud(tick_counter, tb, tfp, 1);
    VPRINTF("IDLE TX: %d (expected: 1)\n", tb->o_tx);
    assert(tb->o_busy == 0);
    assert(tb->o_tx == 1);
}
