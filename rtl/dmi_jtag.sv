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
        Exit2Dr, Exit1Dr, ShiftDr, PauseDr, SelectIrScan, UpdateDr,
        CaptureDr, SelectDrScan, Exit2Ir, Exit1Ir, ShiftIr, PauseIr,
        RunTestIdle, UpdateIr, CaptureIr, TestLogicReset
    } jtag_tap_state;

    typedef enum logic [IR_WIDTH-1:0] {
        Bypass0 = 'h00,
        IdCode = 'h01,
        Dtmcs = 'h10,
        Dmi = 'h11,
        Bypass1 = 'h1f
    } jtag_instruction;

    typedef struct packed {
        logic _reserved;
        logic [10:0] manufid;
        logic [15:0] partnumber;
        logic [3:0] version;
    } jtag_idcode;
    
    typedef struct packed {
        logic [3:0] version;
        logic [5:0] abits;
        logic [1:0] dmistat;
        logic [2:0] idle;
        logic _reserved0;
        logic dmireset;
        logic dmihardreset;
        logic [13:0] _reserved1;
    } jtag_dtmcs;

    typedef struct packed {
        logic [1:0] op;
        logic [31:0] data;
        logic [DMI_ADDR_WIDTH-1:0] address;
    } jtag_dmi;

    localparam int unsigned DMI_REG_WIDTH = 33+DMI_ADDR_WIDTH;
    localparam jtag_idcode REG_IDCODE = '{
        version:'hf,
        partnumber:'hffff,
        manufid:'h7ff,
        _reserved:'b1
    };
    localparam jtag_dtmcs DTMCS_RESET = '{
        version:'h1,
        abits:6'(DMI_ADDR_WIDTH),
        dmistat:'h0,
        idle:'h2,
        _reserved0:'h0,
        dmireset:'h0,
        dmihardreset:'h0,
        _reserved1:'h0
    };

    jtag_tap_state next_state, current_state;
    jtag_instruction current_instruction;
    jtag_dmi reg_dmi;
    logic [DMI_REG_WIDTH:0] reg_shift;
    logic o_td_latch;
    logic [1:0] dmistat;

    assign o_td = o_td_latch;

    always_comb begin
        case (current_state)
            TestLogicReset:
                if (i_tms)
                    next_state = TestLogicReset;
                else
                    next_state = RunTestIdle;
            RunTestIdle:
                if (i_tms)
                    next_state = SelectDrScan;
                else
                    next_state = RunTestIdle;
            SelectDrScan:
                if (i_tms)
                    next_state = SelectIrScan;
                else
                    next_state = CaptureDr;
            CaptureDr, ShiftDr:
                if (i_tms)
                    next_state = Exit1Dr;
                else
                    next_state = ShiftDr;
            Exit1Dr:
                if (i_tms)
                    next_state = UpdateDr;
                else
                    next_state = PauseDr;
            PauseDr:
                if (i_tms)
                    next_state = Exit2Dr;
                else
                    next_state = PauseDr;
            Exit2Dr:
                if (i_tms)
                    next_state = UpdateDr;
                else
                    next_state = ShiftDr;
            UpdateDr, UpdateIr:
                if (i_tms)
                    next_state = SelectDrScan;
                else
                    next_state = RunTestIdle;
            SelectIrScan:
                if (i_tms)
                    next_state = TestLogicReset;
                else
                    next_state = CaptureIr;
            CaptureIr, ShiftIr:
                if (i_tms)
                    next_state = Exit1Ir;
                else
                    next_state = ShiftIr;
            Exit1Ir:
                if (i_tms)
                    next_state = UpdateIr;
                else
                    next_state = PauseIr;
            PauseIr:
                if (i_tms)
                    next_state = Exit2Ir;
                else
                    next_state = PauseIr;
            Exit2Ir:
                if (i_tms)
                    next_state = UpdateIr;
                else
                    next_state = ShiftIr;
            default:
                next_state = TestLogicReset;
        endcase
    end

    initial current_state = TestLogicReset;
    always_ff @ (posedge i_tck) begin
        current_state <= next_state;
    end

    initial current_instruction = IdCode;
    always_ff @ (negedge i_tck) begin
        case (current_state)
            TestLogicReset:
                current_instruction <= IdCode;
            UpdateIr:
                current_instruction <= jtag_instruction'(reg_shift[IR_WIDTH-1:0]);
            default: begin end
        endcase
    end

    initial reg_shift = 0;
    always_ff @ (posedge i_tck) begin
        case (current_state)
            CaptureIr:
                reg_shift[IR_WIDTH-1:0] <= current_instruction;
            CaptureDr:
                case (current_instruction)
                    Dmi:
                        reg_shift <= reg_dmi;
                    IdCode:
                        reg_shift[31:0] <= REG_IDCODE;
                    Dtmcs:
                        // TODO: Update idle with minimum cycles (currently set to
                        // 1 cycle in Run-Test/Idle)
                        // TODO: Ensure dmistat gets set properly here
                        reg_shift[31:0] <= DTMCS_RESET | (int'(dmistat) << 10);
                    default: begin end
                endcase
            ShiftIr:
                reg_shift[IR_WIDTH-1:0] <= {i_td, reg_shift[IR_WIDTH-1:1]};
            ShiftDr:
                case (current_instruction)
                    Dmi:
                        reg_shift <= {i_td, reg_shift[DMI_REG_WIDTH:1]};
                    IdCode, Dtmcs:
                        reg_shift[31:0] <= {i_td, reg_shift[31:1]};
                    default: begin end
                endcase
            default: begin end
        endcase
    end

    initial o_td_latch = 0;
    always_ff @ (negedge i_tck) begin
        if (current_state == ShiftIr || current_state == ShiftDr)
            o_td_latch <= reg_shift[0];
        else
            o_td_latch <= 0;
    end

    initial reg_dmi = 0;
    always_ff @ (negedge i_tck) begin
        if (current_state == UpdateDr)
            if (current_instruction == Dmi)
                // TODO: Process DMI transaction here
                // TODO: Update dmistat with error codes
                reg_dmi <= reg_shift;
            else if (current_instruction == Dtmcs)
                // TODO: Cancel DMI transaction when dmihardreset is written
                if (reg_shift[16] || reg_shift[17]) begin
                    dmistat <= 0;
                    reg_dmi <= 0;
                end
    end

endmodule
