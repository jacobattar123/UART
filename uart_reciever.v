`timescale 1ns / 1ps


//(100000000/9600) = 10416 
// 10416 clock cycles for every bit of the data stream. 
//Use this to find halfway through the transmission of one bit to be sure stable data is being sent. 
module uart_reciever#(parameter CLKS_PER_BIT = 10416)
  (
   input        i_Clock,      
   input        i_Rx_Serial, // serial data that is recieve from putty from computer
   output       o_Rx_DV,      //data valid bit
   output [7:0] o_Rx_Byte       //serial data that is turned into parallel data by the reciever
   );
    
  parameter s_IDLE         = 3'b000;
  parameter s_RX_START_BIT = 3'b001;
  parameter s_RX_DATA_BITS = 3'b010;
  parameter s_RX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg           r_Rx_Data_R = 1'b1;
  reg           r_Rx_Data   = 1'b1;
   
  reg [7:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]     r_Rx_Byte     = 0;
  reg           r_Rx_DV       = 0;
  reg [2:0]     r_SM_Main     = 0;  //main state machine
   
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial;
      r_Rx_Data   <= r_Rx_Data_R;
    end
   
   
  // Purpose: Control RX state machine
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0; // no valid data in idle
            r_Clock_Count <= 0;    // no need to increment clock count
            r_Bit_Index   <= 0;    // no need to increment the bit index
             
            if (r_Rx_Data == 1'b0)          // Start bit detected
              r_SM_Main <= s_RX_START_BIT;  // go to the start bit state
            else
              r_SM_Main <= s_IDLE;          //stay in idle
          end
         
        // Check middle of start bit to make sure it's still low
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2) 
              begin
                if (r_Rx_Data == 1'b0) // data value is low which is correct since we are in the start state. 
                  begin
                    r_Clock_Count <= 0;  // reset counter, found the middle now go to next state
                    r_SM_Main     <= s_RX_DATA_BITS;
                  end
                else    // an error has occurred because for some reason in the start state there is a high value for 
                  r_SM_Main <= s_IDLE; //got back to idle state since the value for the data is high
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1; //if not in the middle of the start bit then increment the clock count
                r_SM_Main     <= s_RX_START_BIT;    //stay in the start bit state
              end
          end // case: s_RX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1) //if less than the limit of CLKS_PER_BIT
              begin
                r_Clock_Count <= r_Clock_Count + 1; //increment the clock count
                r_SM_Main     <= s_RX_DATA_BITS; // stay in data state
              end
            else //if it is == to CLKS_PER_BIT
              begin
                r_Clock_Count          <= 0;  //reset back to zero
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data; // sample the data bit when in the middle of transmission period.
                 
                // Check if we have received all bits
                if (r_Bit_Index < 7) //increment the bit index to get the next bit
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_RX_DATA_BITS; //stay in the data state until all data is recieved
                  end
                else // if r_Bit_Index == 7 
                  begin
                    r_Bit_Index <= 0; // reset the bit index.
                    r_SM_Main   <= s_RX_STOP_BIT; // change to stop bit state.
                  end
              end
          end // case: s_RX_DATA_BITS
     
     
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BIT :
          begin
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1) // if less than the limit of CLKS_PER_BIT
              begin
                r_Clock_Count <= r_Clock_Count + 1; //increment the clock count
                r_SM_Main     <= s_RX_STOP_BIT;    
              end
            else
              begin
                r_Rx_DV       <= 1'b1; // data is valid and ready to be taken
                r_Clock_Count <= 0;    // reset the clock count
                r_SM_Main     <= s_CLEANUP; // go to cleanup state
              end
          end // case: s_RX_STOP_BIT
     
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_SM_Main <= s_IDLE; // go back to idle
            r_Rx_DV   <= 1'b0;   //data no longer valid
          end
         
         
        default :
          r_SM_Main <= s_IDLE;  //default state is idle.
         
      endcase
    end   
   
  assign o_Rx_DV   = r_Rx_DV; //assign the data valid bit 
  assign o_Rx_Byte = r_Rx_Byte; //assign the output data (byte) to what was being manipulated in this module
   
endmodule // uart_rx
