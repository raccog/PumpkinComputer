//////////////////////////////////////////////////////////////////////////////////
//
// Design Name: Debug Module Interface (DMI) JTAG
// Module Name: dmi_jtag
// Description: 
//  A JTAG module that can be used to connect to a RISC-V Debug Module (DM).
//
//  Conforms to IEEE 1149.1 2013 and RISC-V External Debug Support v0.13.2.
//
//  Design inspired by https://github.com/pulp-platform/riscv-dbg/blob/master/src/dmi_jtag.sv
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

// TODO: Implement interface to DMI

module dmi_jtag
    #(parameter int unsigned IR_WIDTH = 5,
    parameter int unsigned DMI_ADDR_WIDTH = 7) (
    input logic i_tck,
    input logic i_tms,
    input logic i_td,
    output logic o_td
);
    typedef enum logic [3:0] {
        EXIT2_DR, EXIT1_DR, SHIFT_DR, PAUSE_DR, SELECT_IR_SCAN, UPDATE_DR,
        CAPTURE_DR, SELECT_DR_SCAN, EXIT2_IR, EXIT1_IR, SHIFT_IR, PAUSE_IR,
        RUN_TEST_IDLE, UPDATE_IR, CAPTURE_IR, TEST_LOGIC_RESET
    } jtag_tap_state_e;

    typedef enum logic [IR_WIDTH-1:0] {
        BYPASS0 = 'h00,
        IDCODE = 'h01,
        DTMCS = 'h10,
        DMI = 'h11,
        BYPASS1 = 'h1f
    } jtag_instruction_e;

    typedef struct packed {
        logic _reserved;
        logic [10:0] manufid;
        logic [15:0] partnumber;
        logic [3:0] version;
    } jtag_idcode_t;
    
    typedef struct packed {
        logic [3:0] version;
        logic [5:0] abits;
        logic [1:0] dmistat;
        logic [2:0] idle;
        logic _reserved0;
        logic dmireset;
        logic dmihardreset;
        logic [13:0] _reserved1;
    } jtag_dtmcs_t;

    typedef struct packed {
        logic [1:0] op;
        logic [31:0] data;
        logic [DMI_ADDR_WIDTH-1:0] address;
    } jtag_dmi_t;

    localparam int unsigned DMI_REG_WIDTH = 33+DMI_ADDR_WIDTH;
    localparam jtag_idcode_t REG_IDCODE = '{
        version:'hf,
        partnumber:'hffff,
        manufid:'h7ff,
        _reserved:'b1
    };
    localparam jtag_dtmcs_t DTMCS_RESET = '{
        version:'h1,
        abits:6'(DMI_ADDR_WIDTH),
        dmistat:'h0,
        idle:'h2,
        _reserved0:'h0,
        dmireset:'h0,
        dmihardreset:'h0,
        _reserved1:'h0
    };

    jtag_tap_state_e next_state, current_state;
    jtag_instruction_e current_instruction;
    jtag_dmi_t reg_dmi;
    logic [DMI_REG_WIDTH:0] reg_shift;
    logic o_td_latch;
    logic [1:0] dmistat;

    logic test_logic_reset, capture_dr, capture_ir, shift_dr,
        shift_ir, update_dr, update_ir;
    logic select_idcode, select_dtmcs, select_dmi;

    assign o_td = o_td_latch;

    assign test_logic_reset = (current_state == TEST_LOGIC_RESET);
    assign capture_dr = (current_state == CAPTURE_DR);
    assign capture_ir = (current_state == CAPTURE_IR);
    assign shift_dr = (current_state == SHIFT_DR);
    assign shift_ir = (current_state == SHIFT_IR);
    assign update_dr = (current_state == UPDATE_DR);
    assign update_ir = (current_state == UPDATE_IR);
    assign select_idcode = (current_instruction == IDCODE);
    assign select_dtmcs = (current_instruction == DTMCS);
    assign select_dmi = (current_instruction == DMI);

    always_comb begin
        case (current_state)
            TEST_LOGIC_RESET:
                next_state = (i_tms) ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:
                next_state = (i_tms) ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_DR_SCAN:
                next_state = (i_tms) ? SELECT_DR_SCAN : CAPTURE_DR;
            CAPTURE_DR, SHIFT_DR:
                next_state = (i_tms) ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR:
                next_state = (i_tms) ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR:
                next_state = (i_tms) ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR:
                next_state = (i_tms) ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR, UPDATE_IR:
                next_state = (i_tms) ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_IR_SCAN:
                next_state = (i_tms) ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR, SHIFT_IR:
                next_state = (i_tms) ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR:
                next_state = (i_tms) ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR:
                next_state = (i_tms) ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR:
                next_state = (i_tms) ? UPDATE_IR : SHIFT_IR;
            default:
                next_state = TEST_LOGIC_RESET;
        endcase
    end

    initial current_state = TEST_LOGIC_RESET;
    always_ff @ (posedge i_tck) begin
        current_state <= next_state;
    end

    initial current_instruction = IDCODE;
    always_ff @ (negedge i_tck) begin
        case (current_state)
            TEST_LOGIC_RESET:
                current_instruction <= IDCODE;
            UPDATE_IR:
                current_instruction <= jtag_instruction_e'(reg_shift[IR_WIDTH-1:0]);
            default: begin end
        endcase
    end

    initial reg_shift = 0;
    always_ff @ (posedge i_tck) begin
        case (current_state)
            CAPTURE_IR:
                reg_shift[IR_WIDTH-1:0] <= current_instruction;
            CAPTURE_DR:
                case (current_instruction)
                    DMI:
                        reg_shift <= reg_dmi;
                    IDCODE:
                        reg_shift[31:0] <= REG_IDCODE;
                    DTMCS:
                        // TODO: Update idle with minimum cycles (currently set to
                        // 1 cycle in Run-Test/Idle)
                        // TODO: Ensure dmistat gets set properly here
                        reg_shift[31:0] <= DTMCS_RESET | (jtag_dtmcs_t'(dmistat) << 10);
                    default: begin end
                endcase
            SHIFT_IR:
                reg_shift[IR_WIDTH-1:0] <= {i_td, reg_shift[IR_WIDTH-1:1]};
            SHIFT_DR:
                case (current_instruction)
                    DMI:
                        reg_shift <= {i_td, reg_shift[DMI_REG_WIDTH:1]};
                    IDCODE, DTMCS:
                        reg_shift[31:0] <= {i_td, reg_shift[31:1]};
                    default: begin end
                endcase
            default: begin end
        endcase
    end

    initial o_td_latch = 0;
    always_ff @ (negedge i_tck) begin
        if (current_state == SHIFT_IR || current_state == SHIFT_DR)
            o_td_latch <= reg_shift[0];
        else
            o_td_latch <= 0;
    end

    initial reg_dmi = 0;
    always_ff @ (negedge i_tck) begin
        if (current_state == UPDATE_DR)
            if (current_instruction == DMI)
                // TODO: Process DMI transaction here
                // TODO: Update dmistat with error codes
                reg_dmi <= reg_shift;
            else if (current_instruction == DTMCS)
                // TODO: Cancel DMI transaction when dmihardreset is written
                if (reg_shift[16] || reg_shift[17]) begin
                    dmistat <= 0;
                    reg_dmi <= 0;
                end
    end

endmodule
