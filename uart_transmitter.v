`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/15/2022 10:51:49 AM
// Design Name: 
// Module Name: uart_transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx(input clk, en, start, [7:0] in, output reg out, reg done, reg busy);

parameter RESET = 3'b001, IDLE = 3'b010, START_BIT = 3'b011, DATA_BITS = 3'b100, STOP_BIT = 3'b101;
   
reg [2:0] state;
reg [7:0] data;
reg [2:0] bit_idx;
wire [2:0] idx;

assign idx = bit_idx;

always @(posedge clk) begin

    case(state) 
        default: state <= IDLE;
        IDLE: begin
            out     <= 1'b1; //idle high 
            done    <= 1'b0;
            busy    <= 1'b0; 
            bit_idx <= 3'b0;
            data    <= 8'b0;
            if (start & en)begin
                data    <= in;
                state   <= START_BIT;
            end //end start and enable
        end
        START_BIT: begin
            out     <= 1'b0; // start bit should be low 
            busy    <= 1'b1;
            state   <= DATA_BITS;
        end //End case start_bit
        DATA_BITS: begin
            out     <= data[idx];
            if (&bit_idx) begin
                bit_idx     <= 3'b0;
                state       <= STOP_BIT;
                
            end else bit_idx <= bit_idx + 1'b1;
        end // end data_bits 
        STOP_BIT: begin
            out <= 1;
            done    <= 1'b1;
            data    <= 8'b0;
            state   <= IDLE;     
        end
    endcase
end // end main always


endmodule
