#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <memory>
#include <string>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "verilated_vpi.h"

#define VPRINTF(...) \
    if (tb.verbose()) printf(__VA_ARGS__)

namespace fs = std::filesystem;

template <class VerilatorTestBench>
class MainTestBench {
public:
    MainTestBench(std::string moduleName) : m_tb{new VerilatorTestBench},
        m_vcd{new VerilatedVcdC}, m_moduleName{moduleName}, m_vcdPath{},
        m_verbose{false}, m_tickCount{1} {
        // Start to trace signals and save to VCD file
        Verilated::traceEverOn(true);
        m_tb->trace(m_vcd.get(), 99);
        m_vcdPath += fs::path{"vcd"} / fs::path{moduleName + ".vcd"};
        m_vcd->open(m_vcdPath.c_str());
    }

    VerilatorTestBench *operator->() {return m_tb.get();}
    // Parse command line arguments to setup the test bench options
    void parseArgs(int argc, char **argv) {
        // Check for verbose command argument
        if (argc > 1) {
            for (int i = 1; i < argc; ++i) {
                if (strcmp(argv[i], "-v") == 0) {
                    m_verbose = true;
                }
            }
        }
    }
    // Simulates a clock tick and records all signals to a VCD file.
    // TODO: Add bool argument (default true) that controls whether this function
    // flushes the VCD file.
    void tick() {

        // Eval right before clock edge
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10 - 2);

        // Eval clock rising edge
        m_tb->i_clk = 1;
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10);

        // Eval clock falling edge
        m_tb->i_clk = 0;
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10 + 5);

        // Cleanup the clock tick
        m_vcd->flush();
        m_tickCount += 1;
    }
    // Simulates multiple clock ticks at once
    // TODO: Only flush VCD file after for loop is done
    void tick(int ticks) {
        for (int i = 0; i < ticks; ++i) {
            tick();
        }
    }
    // Returns true if running in verbose mode
    bool verbose() {return m_verbose;}
private:
    std::unique_ptr<VerilatorTestBench> m_tb;
    std::unique_ptr<VerilatedVcdC> m_vcd;
    std::string m_moduleName;
    fs::path m_vcdPath;
    bool m_verbose;
    uint64_t m_tickCount;
};

