//////////////////////////////////////////////////////////////////////////////////
//
// Design Name: UART Transmitter
// Module Name: uart_tx
// Description: 
//  An 8-bit data, 1-bit stop, 1-bit parity UART transmitter running at 115200
//  baud.
//
// Signals:
//  - i_clk: The clock signal to run this UART. It must be running at 100 MHz.
//  - i_rst: When this signal is asserted, the UART transmitter will be held
//  in reset, starting on the following rising clock edge. It will be held in
//  reset until the rising clock edge following the negation of [i_rst]. While
//  held in reset, [o_tx] will be asserted and [o_busy] will be negated.
//  - i_start: When this signal is asserted and the transmitter is not busy,
//  it will pull [i_data] into a register and start sending it over [o_tx].
//  - i_data: An 8-bit data input that is read on the rising clock edge
//  following the assertion of [i_start].
//  - o_tx: The wire used to transmit serial data.
//  - o_busy: This will be asserted when the transmitter is sending data over
//  [o_tx]. After sending the stop bit, [o_busy] will be negated if [i_start]
//  is not asserted. If [i_start] is asserted, [o_busy] will stay asserted
//  for the next transmission.
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none


module uart_tx(
    input wire i_clk,
    input wire i_rst,
    input wire i_start,
    input wire [7:0] i_data,
    output reg o_tx,
    output reg o_busy
    );
    
    parameter INPUT_CLOCK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter CYCLES_PER_BAUD = INPUT_CLOCK_FREQ / BAUD_RATE;
    
    parameter reg [3:0] IDLE_STATE   = 4'h0;
    parameter reg [3:0] START_STATE  = 4'h1;
    parameter reg [3:0] PARITY_STATE = 4'ha;
    parameter reg [3:0] STOP_STATE   = 4'hb;
    
    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [31:0] baud_counter;
    reg baud_strobe;
    reg [7:0] tx_shift;
    reg [7:0] tx_hold;
    
    // Set next state whenever inputs change
    initial next_state = IDLE_STATE;
    always @ (*) begin
        if (i_rst)
            next_state = IDLE_STATE;
        else case (current_state)
            IDLE_STATE, STOP_STATE:
                if (i_start)
                    next_state = START_STATE;
                else
                    next_state = IDLE_STATE;
            default:
                if (current_state < STOP_STATE)
                    next_state = current_state + 1;
                else
                    next_state = IDLE_STATE;
        endcase
    end
    
    // Baud counter (only runs when not idle)
    initial baud_counter = 0;
    initial baud_strobe = 0;
    always @ (posedge i_clk) begin
        if (current_state == IDLE_STATE) begin
            if (i_start)
                baud_strobe <= 1;
            else
                baud_strobe <= 0;
            baud_counter <= 0;
        end else if (baud_counter >= CYCLES_PER_BAUD) begin
            baud_strobe <= 1'b1;
            baud_counter <= 0;
        end else begin
            baud_counter <= baud_counter + 1'b1;
            baud_strobe <= 0;
        end
    end
    
    // State transitions
    initial current_state = IDLE_STATE;
    always @ (posedge i_clk) begin
        if (i_rst)
            current_state <= IDLE_STATE;
        else if (baud_strobe || (current_state == IDLE_STATE && i_start))
            current_state <= next_state;
    end
    
    // Set o_busy
    initial o_busy = 0;
    always @ (posedge i_clk) begin
        if (i_rst)
            o_busy <= 0;
        else
            o_busy <= (current_state >= START_STATE && current_state <= STOP_STATE);
    end
    
    // Shift data into register
    initial tx_shift = 0;
    initial tx_hold = 0;
    always @ (posedge i_clk) begin
        if (!i_rst && baud_strobe) begin
            case (current_state)
                START_STATE: begin
                    tx_shift <= i_data;
                    tx_hold <= i_data;
                end
                IDLE_STATE, PARITY_STATE, STOP_STATE:
                    tx_shift <= 0;
                default:
                    if (current_state < PARITY_STATE)
                        tx_shift <= tx_shift >> 1;
            endcase
        end
    end
    
    // Toggle tx_data
    initial o_tx = 1;
    always @ (posedge i_clk) begin
        if (i_rst)
            o_tx <= 1;
        else if (baud_strobe)
            case (current_state)
                IDLE_STATE, STOP_STATE:
                    o_tx <= 1;
                START_STATE:
                    o_tx <= 0;
                PARITY_STATE:
                    o_tx <= ^tx_hold;
                default:
                    if (current_state < STOP_STATE)
                        o_tx <= tx_shift[0];
            endcase
    end
    
endmodule
