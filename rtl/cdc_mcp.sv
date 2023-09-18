//////////////////////////////////////////////////////////////////////////////////
//
// Design Name: Clock Domain Crossing (CDC) Multi-Cycle Path (MCP) with
//  Acknowledge
// Module Name: cdc_mcp
// Description: 
//  A CDC MCP with an acknowledge signal as described in "Clock Domain
//  Crossing (CDC) Design & Verification Techniques Using SystemVerilog" by
//  Clifford E. Cummings [1] section 5.6.3.
//
//  [1]: http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module cdc_mcp
    #(parameter int unsigned DATA_WIDTH = 32) (
    input logic i_aclk,
    input logic i_arst_n,
    output logic o_aready,
    input logic i_asend,
    input logic [DATA_WIDTH-1:0] i_adata,
    input logic i_bclk,
    input logic i_brst_n,
    input logic i_bload,
    output logic o_bvalid,
    output logic [DATA_WIDTH-1:0] o_bdata
);
    logic [DATA_WIDTH-1:0] adata;
    logic aen, back;

    cdc_mcp_sender #(DATA_WIDTH) i_sender (
        .i_aclk,
        .i_arst_n,
        .o_aready,
        .i_asend,
        .i_adata,
        .o_adata(adata),
        .o_aen(aen),
        .i_back(back)
    );

    cdc_mcp_receiver #(DATA_WIDTH) i_receiver (
        .i_bclk,
        .i_brst_n,
        .i_bload,
        .o_bvalid,
        .o_bdata,
        .i_adata(adata),
        .i_aen(aen),
        .o_back(back)
    );

endmodule

/* verilator lint_off DECLFILENAME */
module cdc_mcp_sender
    #(parameter int unsigned DATA_WIDTH = 32) (
    input logic i_aclk,
    input logic i_arst_n,
    output logic o_aready,
    input logic i_asend,
    input logic [DATA_WIDTH-1:0] i_adata,
    output logic [DATA_WIDTH-1:0] o_adata,
    output logic o_aen,
    input logic i_back  // read as b-acknowledge
);
    typedef enum logic {
        READY = '1,
        BUSY = '0
    } sender_state_e;

    logic aack, aack_q1, aack_q2, aack_q3, aen_q, adata_load;
    sender_state_e current_state, next_state;
    logic [DATA_WIDTH-1:0] adata_q;

    assign o_aready = current_state;
    assign o_aen = aen_q;
    assign o_adata = adata_q;

    assign adata_load = i_asend && o_aready;
    assign aack = aack_q3 ^^ aack_q2;

    always_ff @ (posedge i_aclk or negedge i_arst_n) begin
        if (!i_arst_n)
            current_state <= READY;
        else
            current_state <= next_state;
    end

    always_comb begin
        case (current_state)
            READY:
                if (i_asend)
                    next_state = BUSY;
                else
                    next_state = READY;
            BUSY:
                if (aack)
                    next_state = READY;
                else
                    next_state = BUSY;
        endcase
    end

    always_ff @ (posedge i_aclk or negedge i_arst_n) begin
        if (!i_arst_n)
            adata_q <= 0;
        else if (adata_load)
            adata_q <= i_adata;
    end

    always_ff @ (posedge i_aclk or negedge i_arst_n) begin
        if (!i_arst_n)
            aen_q <= 0;
        else
            aen_q <= adata_load ^^ aen_q;
    end

    always_ff @ (posedge i_aclk or negedge i_arst_n) begin
        if (!i_arst_n) begin
            aack_q1 <= 0;
            aack_q2 <= 0;
            aack_q3 <= 0;
        end else begin
            aack_q1 <= i_back;
            aack_q2 <= aack_q1;
            aack_q3 <= aack_q2;
        end
    end

endmodule

module cdc_mcp_receiver
    #(parameter int unsigned DATA_WIDTH = 32) (
    input logic i_bclk,
    input logic i_brst_n,
    input logic i_bload,
    output logic o_bvalid,
    output logic [DATA_WIDTH-1:0] o_bdata,
    input logic [DATA_WIDTH-1:0] i_adata,
    input logic i_aen,
    output logic o_back  // read as b-acknowledge
);
    typedef enum logic {
        READY = '1,
        WAIT = '0
    } receiver_state_e;

    logic bdata_load, back_q, ben, ben_q1, ben_q2, ben_q3;
    receiver_state_e current_state, next_state;
    logic [DATA_WIDTH-1:0] bdata_q;

    assign o_bvalid = current_state;
    assign bdata_load = o_bvalid && i_bload;
    assign o_back = back_q;
    assign ben = ben_q3 ^^ ben_q2;
    assign o_bdata = bdata_q;

    always_ff @ (posedge i_bclk or negedge i_brst_n) begin
        if (!i_brst_n)
            current_state <= WAIT;
        else
            current_state <= next_state;
    end

    always_comb begin
        case (current_state)
            READY:
                if (i_bload)
                    next_state = WAIT;
                else
                    next_state = READY;
            WAIT:
                if (ben)
                    next_state = READY;
                else
                    next_state = WAIT;
        endcase
    end

    always_ff @ (posedge i_bclk or negedge i_brst_n) begin
        if (!i_brst_n)
            bdata_q <= 0;
        else if (bdata_load)
            bdata_q <= i_adata;
    end

    always_ff @ (posedge i_bclk or negedge i_brst_n) begin
        if (!i_brst_n)
            back_q <= 0;
        else
            back_q <= bdata_load ^^ back_q;
    end

    always_ff @ (posedge i_bclk or negedge i_brst_n) begin
        if (!i_brst_n) begin
            ben_q1 <= 0;
            ben_q2 <= 0;
            ben_q3 <= 0;
        end else begin
            ben_q1 <= i_aen;
            ben_q2 <= ben_q1;
            ben_q3 <= ben_q2;
        end
    end

endmodule
/* verilator lint_on DECLFILENAME */
