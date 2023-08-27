#include "Vuart_tx.h"

#include "sim_common.h"


// 100 MHz System Clock Rate
const unsigned SYSTEM_CLOCK_RATE = (100 * 1000 * 1000);
const unsigned BAUD_RATE = 115200;
const unsigned CYCLES_PER_BAUD = SYSTEM_CLOCK_RATE / BAUD_RATE;

void tickBaud(MainTestBench<Vuart_tx> &tb, unsigned baud_ticks) {
    for (unsigned i = 0; i < baud_ticks; ++i) {
        tb.tick(CYCLES_PER_BAUD + 1);
    }
}

void test_transmit(MainTestBench<Vuart_tx> &tb, uint8_t data, bool continuous) {
    auto sig = tb.signals();
    sig->i_data = data;
    sig->i_start = 1;

    // Start bit
    // If idle, takes 2 clock ticks to register change from [i_start] and move out of
    // idle state
    if (!sig->o_busy) {
        VPRINTF("IDLE TX: %d (expected: 1)\n", sig->o_tx);
        assert(sig->o_tx == 1);
        tb.tick(2);
    } else {
        tickBaud(tb, 1);
    }
    VPRINTF("START TX: %d (expected: 0)\n", sig->o_tx);
    assert(sig->o_busy == 1);
    assert(sig->o_tx == 0);

    if (!continuous) {
        sig->i_start = 0;
    }

    // Data bits
    for (int i = 0; i < 8; ++i) {
        tickBaud(tb, 1);
        uint8_t expected_tx = (data >> i) & 1;
        VPRINTF("DATA TX: %d (expected: %d)\n", sig->o_tx, expected_tx);
        assert(sig->o_busy == 1);
        assert(sig->o_tx == expected_tx);
    }

    // Parity bit
    uint8_t parity = 0;
    for (int i = 0; i < 8; ++i) {
        if (((data >> i) & 1) == 1) {
            parity += 1;
        }
    }
    parity %= 2;
    tickBaud(tb, 1);
    VPRINTF("PARITY TX: %d (expected: %d)\n", sig->o_tx, parity);
    assert(sig->o_busy == 1);
    assert(sig->o_tx == parity);

    // Stop bit
    tickBaud(tb, 1);
    VPRINTF("STOP TX: %d (expected: 1)\n", sig->o_tx);
    assert(sig->o_busy == 1);
    assert(sig->o_tx == 1);
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    MainTestBench<Vuart_tx> tb("uart_tx");
    tb.parseArgs(argc, argv);
    auto sig = tb.signals();

    VPRINTF("Starting test bench for `uart_tx`\n");

    // Ensure reset can be held for a few baud cycles
    sig->i_rst = 1;
    tickBaud(tb, 1);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    tickBaud(tb, 10);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    // Ensure transmitter stays idle when out of reset
    sig->i_rst = 0;
    sig->i_start = 0;
    tickBaud(tb, 1);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    tickBaud(tb, 10);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    // Ensure transmitter can transmit a valid data byte
    const uint8_t BYTE0 = 0xab;
    test_transmit(tb, BYTE0, false);

    // Ensure transmitter goes back to idle state
    tickBaud(tb, 1);
    VPRINTF("IDLE TX: %d (expected: 1)\n", sig->o_tx);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    // Ensure transmitter can send continuous bytes
    const uint8_t BYTES0[] = {0xcd, 0xef, 0x55, 0x00};
    for (unsigned long i = 0; i < sizeof(BYTES0); ++i) {
        test_transmit(tb, BYTES0[i], i != sizeof(BYTES0) - 1);
    }

    // Ensure transmitter goes back to idle state
    tickBaud(tb, 1);
    VPRINTF("IDLE TX: %d (expected: 1)\n", sig->o_tx);
    assert(sig->o_busy == 0);
    assert(sig->o_tx == 1);

    VPRINTF("Success: `uart_tx`\n");
}
