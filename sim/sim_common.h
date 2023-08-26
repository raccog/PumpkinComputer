#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "verilated.h"
#include "verilated_vcd_c.h"

#define VPRINTF(...) \
    if (tb.verbose()) printf(__VA_ARGS__)

template <class VerilatorTestBench>
class MainTestBench {
public:
    MainTestBench(std::string moduleName) : m_tb{new VerilatorTestBench}, m_vcd{new VerilatedVcdC}, m_moduleName{moduleName}, m_verbose{false}, m_tickCount{1} {
        Verilated::traceEverOn(true);
        m_tb->trace(m_vcd.get(), 99);
        m_vcd->open((m_moduleName + ".vcd").c_str());
    }

    std::shared_ptr<VerilatorTestBench> signals() {return m_tb;}
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
    void tick() {
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10 - 2);
        m_tb->i_clk = 1;
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10);
        m_tb->i_clk = 0;
        m_tb->eval();
        m_vcd->dump(m_tickCount * 10 + 5);
        m_vcd->flush();
        m_tickCount += 1;
    }
    void tick(int ticks) {
        for (int i = 0; i < ticks; ++i) {
            tick();
        }
    }
    bool verbose() {return m_verbose;}
private:
    std::shared_ptr<VerilatorTestBench> m_tb;
    std::unique_ptr<VerilatedVcdC> m_vcd;
    std::string m_moduleName;
    bool m_verbose;
    uint64_t m_tickCount;
};

