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
    #(parameter IR_WIDTH = 5,
    DMI_ADDR_WIDTH = 7) (
    input wire i_tck,
    input wire i_tms,
    input wire i_td,
    output wire o_td
);
    wire select_dmi, capture, shift, update;
    wire tap_tdo;

    reg [33+DMI_ADDR_WIDTH:0] r_dmi, r_shift;
    reg o_td_latch;

    // TODO: Fix if it switches to o_td_latch before the shift register is
    // latched
    assign o_td = (select_dmi) ? o_td_latch : tap_tdo;

    initial r_shift = 0;
    always @ (posedge i_tck) begin
        if (select_dmi)
            if (capture)
                r_shift <= r_dmi;
            else if (shift)
                r_shift <= {i_td, r_shift[33+DMI_ADDR_WIDTH:1]};
    end

    initial o_td_latch = 0;
    always @ (negedge i_tck) begin
        if (select_dmi && shift)
            o_td_latch <= r_shift[0];
    end

    initial r_dmi = 0;
    always @ (negedge i_tck) begin
        if (select_dmi && update)
            r_dmi <= r_shift;
    end

    dmi_jtag_tap #(
        .IR_WIDTH(IR_WIDTH)
    ) h_dmi_jtag_tap (
        .i_tck,
        .i_tms,
        .i_td,
        .o_td(tap_tdo),
        .o_select_dmi(select_dmi),
        .o_capture(capture),
        .o_shift(shift),
        .o_update(update)
    );

endmodule
