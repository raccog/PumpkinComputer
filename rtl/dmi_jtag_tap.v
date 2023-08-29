//////////////////////////////////////////////////////////////////////////////////
//
// Design Name: Debug Module Interface (DMI) JTAG Test Access Port (TAP)
// Module Name: dmi_jtag_tap
// Description: 
//  A JTAG TAP that can be used to connect to a RISC-V Debug Module (DM).
//
//  Conforms to IEEE 1149.1 2013 and RISC-V External Debug Support v0.13.2.
//
//  Design inspired by https://github.com/pulp-platform/riscv-dbg/blob/master/src/dmi_jtag_tap.sv
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

// TODO: Implement interface to DMI

module dmi_jtag_tap
    #(parameter IR_WIDTH = 5) (
    input wire i_tck,
    input wire i_tms,
    input wire i_td,
    output wire o_td,
    output wire o_select_dmi,
    output wire o_capture,
    output wire o_shift,
    output wire o_update
);
    /* verilator lint_off UNUSEDPARAM */
    localparam [3:0]
        EXIT2_DR = 4'h0,
        EXIT1_DR = 4'h1,
        SHIFT_DR = 4'h2,
        PAUSE_DR = 4'h3,
        SELECT_IR_SCAN = 4'h4,
        UPDATE_DR = 4'h5,
        CAPTURE_DR = 4'h6,
        SELECT_DR_SCAN = 4'h7,
        EXIT2_IR = 4'h8,
        EXIT1_IR = 4'h9,
        SHIFT_IR = 4'ha,
        PAUSE_IR = 4'hb,
        RUN_TEST_IDLE = 4'hc,
        UPDATE_IR = 4'hd,
        CAPTURE_IR = 4'he,
        TEST_LOGIC_RESET = 4'hf;

    localparam [4:0]
        BYPASS0 = 5'h00,
        IDCODE = 5'h01,
        DTMCS = 5'h10,
        DMI = 5'h11,
        BYPASS1 = 5'h1f;
    /* verilator lint_on UNUSEDPARAM */

    reg [3:0] w_next_state, r_current_state;
    reg [IR_WIDTH-1:0] r_instruction;
    reg r_tdo_latch;
    reg [31:0] r_idcode, r_dtmcs, r_shift;

    assign o_select_dmi = (r_instruction == DMI);
    assign o_capture = (r_current_state == CAPTURE_DR);
    assign o_shift = (r_current_state == SHIFT_DR);
    assign o_update = (r_current_state == UPDATE_DR);

    // Next state logic
    initial w_next_state = TEST_LOGIC_RESET;
    always @ (*) begin
        case (r_current_state)
            TEST_LOGIC_RESET:
                if (i_tms)
                    w_next_state = TEST_LOGIC_RESET;
                else
                    w_next_state = RUN_TEST_IDLE;
            RUN_TEST_IDLE:
                if (i_tms)
                    w_next_state = SELECT_DR_SCAN;
                else
                    w_next_state = RUN_TEST_IDLE;
            SELECT_DR_SCAN:
                if (i_tms)
                    w_next_state = SELECT_IR_SCAN;
                else
                    w_next_state = CAPTURE_DR;
            CAPTURE_DR, SHIFT_DR:
                if (i_tms)
                    w_next_state = EXIT1_DR;
                else
                    w_next_state = SHIFT_DR;
            EXIT1_DR:
                if (i_tms)
                    w_next_state = UPDATE_DR;
                else
                    w_next_state = PAUSE_DR;
            PAUSE_DR:
                if (i_tms)
                    w_next_state = EXIT2_DR;
                else
                    w_next_state = PAUSE_DR;
            EXIT2_DR:
                if (i_tms)
                    w_next_state = UPDATE_DR;
                else
                    w_next_state = SHIFT_DR;
            UPDATE_DR, UPDATE_IR:
                if (i_tms)
                    w_next_state = SELECT_DR_SCAN;
                else
                    w_next_state = RUN_TEST_IDLE;
            SELECT_IR_SCAN:
                if (i_tms)
                    w_next_state = TEST_LOGIC_RESET;
                else
                    w_next_state = CAPTURE_IR;
            CAPTURE_IR, SHIFT_IR:
                if (i_tms)
                    w_next_state = EXIT1_IR;
                else
                    w_next_state = SHIFT_IR;
            EXIT1_IR:
                if (i_tms)
                    w_next_state = UPDATE_IR;
                else
                    w_next_state = PAUSE_IR;
            PAUSE_IR:
                if (i_tms)
                    w_next_state = EXIT2_IR;
                else
                    w_next_state = PAUSE_IR;
            EXIT2_IR:
                if (i_tms)
                    w_next_state = UPDATE_IR;
                else
                    w_next_state = SHIFT_IR;
            default:
                w_next_state = TEST_LOGIC_RESET;
        endcase
    end

    initial r_current_state = TEST_LOGIC_RESET;
    always @ (posedge i_tck) begin
        r_current_state <= w_next_state;
    end

    // TODO: Fill out idcode fields
    initial r_idcode = 32'hffffffff;     // Custom IDCODE
    initial r_shift = 0;
    always @ (posedge i_tck) begin
        case (r_current_state)
            CAPTURE_IR:
                r_shift[IR_WIDTH-1:0] <= r_instruction;
            SHIFT_IR:
                r_shift[IR_WIDTH-1:0] <= {i_td, r_shift[IR_WIDTH-1:1]};
            CAPTURE_DR:
                case (r_instruction)
                    IDCODE:
                        r_shift <= r_idcode;
                    DTMCS:
                        r_shift <= r_dtmcs;
                    default:
                        r_shift <= 0;
                endcase
            SHIFT_DR:
                case (r_instruction)
                    IDCODE, DTMCS:
                        r_shift <= {i_td, r_shift[31:1]};
                    default:
                        r_shift <= r_shift;
                endcase
            default:
                r_shift <= r_shift;
        endcase
    end

    initial r_instruction = IDCODE;
    always @ (negedge i_tck) begin
        case (r_current_state)
            TEST_LOGIC_RESET:
                r_instruction <= IDCODE;
            UPDATE_IR:
                r_instruction <= r_shift[IR_WIDTH-1:0];
            default:
                r_instruction <= r_instruction;
        endcase
    end

    // TODO: Fill out dtmcs fields
    initial r_dtmcs = 0;
    always @ (negedge i_tck) begin
        if (r_current_state == UPDATE_DR)
            if (r_instruction == DTMCS)
                r_dtmcs <= r_shift;
    end

    initial r_tdo_latch = 1'b0;
    always @ (negedge i_tck) begin
        if (r_current_state == SHIFT_IR || r_current_state == SHIFT_DR)
            r_tdo_latch <= r_shift[0];
    end
    assign o_td = r_tdo_latch;

endmodule
