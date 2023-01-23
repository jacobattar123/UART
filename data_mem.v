`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2022 12:24:53 AM
// Design Name: 
// Module Name: data_mem
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


module data_mem(input en, output [7:0] data);
reg [3:0] x;
reg [7:0] DM [6:0];

initial begin
    x = 0;
end

always @(posedge en)begin
    if (5 < x) x <= 0;
    else x <= x + 1;
end 

assign data = DM[x];

initial begin
    $readmemb("data.mem", DM);
    end 

endmodule
