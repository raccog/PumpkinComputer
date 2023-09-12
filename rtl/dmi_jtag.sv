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
    input logic i_clk,  // i_tck
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

    typedef enum logic [1:0] {
        NO_ERROR,
        OPERATION_FAILED,
        ALREADY_IN_PROGRESS
    } jtag_dmi_error_e;

    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE
    } jtag_dmi_state_e;

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
    localparam jtag_idcode_t IDCODE_RESET = '{
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

    jtag_tap_state_e next_state, current_state /* verilator public_flat */;
    jtag_instruction_e current_instruction;
    logic [IR_WIDTH-1:0] reg_instruction;
    jtag_idcode_t reg_idcode;
    jtag_dtmcs_t reg_dtmcs;
    jtag_dmi_t reg_dmi;
    logic tdo_latch;

    /* verilator lint_off UNUSEDSIGNAL */
    jtag_dmi_state_e dmi_state;
    jtag_dmi_error_e dmi_error;
    logic [31:0] dmi_data;
    logic [DMI_ADDR_WIDTH-1:0] dmi_address;
    /* verilator lint_on UNUSEDSIGNAL */

    logic test_logic_reset, capture_dr, capture_ir, shift_dr,
        shift_ir, update_dr, update_ir;
    logic select_idcode, select_dtmcs, select_dmi;

    assign o_td = tdo_latch;

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
    always_ff @ (posedge i_clk) begin
        current_state <= next_state;
    end

    initial current_instruction = IDCODE;
    always_ff @ (negedge i_clk) begin
        if (test_logic_reset)
            current_instruction <= IDCODE;
        else if (update_ir)
            current_instruction <= jtag_instruction_e'(reg_instruction);
    end

    initial reg_instruction = 0;
    always_ff @ (posedge i_clk) begin
        if (test_logic_reset || capture_ir)
            reg_instruction <= IR_WIDTH'(4'b0101);
        else if (shift_ir)
            reg_instruction <= {i_td, reg_instruction[IR_WIDTH-1:1]};
    end

    initial reg_idcode = IDCODE_RESET;
    always_ff @ (posedge i_clk) begin
        if (test_logic_reset)
            reg_idcode <= IDCODE_RESET;
        else if (select_idcode)
            if (capture_dr)
                reg_idcode <= IDCODE_RESET;
            else if (shift_dr)
                reg_idcode <= {i_td, reg_idcode[31:1]};
    end

    initial reg_dtmcs = DTMCS_RESET;
    always_ff @ (posedge i_clk) begin
        if (test_logic_reset)
            reg_dtmcs <= DTMCS_RESET;
        else if (select_dtmcs)
            if (capture_dr)
                reg_dtmcs <= DTMCS_RESET | (jtag_dtmcs_t'(dmi_error) << 10);
            else if (shift_dr)
                reg_dtmcs <= {i_td, reg_dtmcs[31:1]};
    end

    initial reg_dmi = 0;
    always_ff @ (posedge i_clk) begin
        if (test_logic_reset)
            reg_dmi <= 0;
        else if (select_dmi)
            if (capture_dr)
                // TODO: Update data from DMI transaction here
                reg_dmi <= reg_dmi;
            else if (shift_dr)
                reg_dmi <= {i_td, reg_dmi[DMI_REG_WIDTH:1]};
    end

    initial tdo_latch = 1'b0;
    always_ff @ (negedge i_clk) begin
        tdo_latch <= 1'b0;
        if (shift_ir)
            tdo_latch <= reg_instruction[0];
        else if (shift_dr)
            if (select_idcode)
                tdo_latch <= reg_idcode[0];
            else if (select_dtmcs)
                tdo_latch <= reg_dtmcs[0];
            else if (select_dmi)
                tdo_latch <= reg_dmi[0];
    end

    initial dmi_state = IDLE;
    initial dmi_error = NO_ERROR;
    initial dmi_data = 0;
    initial dmi_address = 0;
    always_ff @ (negedge i_clk) begin
        if (update_dr)
            if (select_dtmcs)
                if (reg_dtmcs.dmireset)
                    dmi_error <= NO_ERROR;
                else if (reg_dtmcs.dmihardreset) begin
                    dmi_error <= NO_ERROR;
                    dmi_state <= IDLE;
                    dmi_data <= 0;
                    dmi_address <= 0;
                end
            else if (select_dmi) begin
                // TODO: Ensure DMI is not in the middle of a transaction
                dmi_error <= OPERATION_FAILED;
                dmi_state <= jtag_dmi_state_e'(reg_dmi.op);
                dmi_data <= reg_dmi.data;
                dmi_address <= reg_dmi.address;
                // TODO: Start DMI transaction
            end
    end

endmodule
