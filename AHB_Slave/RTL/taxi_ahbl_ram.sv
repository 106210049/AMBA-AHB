/******************************************************************************
 *
 * taxi_apb_dp_ram.sv
 *   
 ******************************************************************************/
`begin_keywords "1800-2012"
`default_nettype none  // turn off implicit data types

module taxi_ahbl_ram #
  (
  //Parameters
  parameter ADDR_WIDTH=32,                               //Address bus width
  parameter DATA_WIDTH=32,                               //Data bus width
  parameter MEMORY_DEPTH=512,                            //Slave memory 

  parameter WAIT_WRITE=0,                                //Number of wait cycles issued by the slave in response to a 'write' transfer
  parameter WAIT_READ=0,                                 //Number of wait cycles issued by the slave in response to a 'read' transfer

  parameter REGISTER_SELECT_BITS=12,                     //Memory mapping - each slave's internal memory has maximum 2^REGISTER_SELECT_BITS-1 bytes (depends on MEMORY_DEPTH)
  parameter SLAVE_SELECT_BITS=20                         //Memory mapping - width of slave address

   )
   (
    //Inputs 
    input wire i_hclk, //All signal timings are related to the rising edge of hclk
    input wire i_hreset, //Active low bus reset
   
    taxi_ahbl_if.slv s_ahb
    );
  
  //--------------------------------------------------------------------------//
     // Set timeunit and timeprecision per MSIP standard

`ifndef SYNTHESIS
  timeunit 1ps;
  timeprecision 1ps;
`endif

  localparam IDLE=2'b00;                                 //Indicates that no data transfer is required
  localparam BUSY=2'b01;                                 //The BUSY transfer type enables masters to insert idle cycles in the middle of a burst
  localparam NONSEQ= 2'b10;                              //Indicates a single transfer or the first transfer of a burst
  localparam SEQ=2'b11;                                  //The remaining transfers in a burst are SEQUENTIAL

  localparam BYTE=3'b000;                                //Transfer size encodding for 1-byte transfers. Note: 32-bit databus is assumed
  localparam HALFWORD=3'b001;                            //Transfer size encodding for 2-byte transfers, i.e. halfword. Note: 32-bit databus is assumed
  localparam WORD=3'b010;                                //Transfer size encodding for 4-byte transfers, i.e. word. Note: 32-bit databus is assumed

  //Internal signals
  logic [MEMORY_DEPTH-1:0][7:0] mem;                     //Deafult: 512 entries of a 1 byte each (single byte access is supported)
  logic [4:0]                   wait_counter;                              //Used to extend read/write transfers. Note: width can be parametrized if required
  logic                         write_en;                                        //write_en signal rises to logic high for one cycle when the write data is valid. Write operation to the internl slave memory is synchronized to the positive edge of the clock when this signal is high. 

  logic [2:0]                   hsize_samp;                                //Sampled packet. This is required to execute trasfers with wait states since the i_x signals are modified during the wait phase to accomodate the following transfer
  logic [ADDR_WIDTH-1:0]        haddr_samp;                     //Sampled packet
  logic [DATA_WIDTH-1:0]        hwdata_samp;                    //Sampled packet
  logic                         hwrite_samp;                                     //Sampled packet
  logic                         hsel_samp;                                       //Sampled packet

  //HDL code

  always @(posedge i_hclk or negedge i_hreset)
    if (!i_hreset) begin
      s_ahb.o_hresp<=1'b0;                                                                             //OKAY resposne is issued during reset
      wait_counter<='0;
      write_en<=1'b0;
    end
    else if ((s_ahb.i_hsel&&s_ahb.i_hreadyin)||(hsel_samp&&!s_ahb.o_hreadyout))                                    //Slave is activated if on a positive edge hready is logic high and i_sel is logic high (first clock cycle) or after it has been activated but inserts wait states
      case (s_ahb.i_htrans)
        IDLE: begin
          s_ahb.o_hresp<=1'b0;                                                                           //Slave must provide zero wait state OKAY response to IDLE transfers and the transfer must be ignored by the slave
          s_ahb.o_hreadyout<=1'b1;                                                                       //Issue logic high hready signal during IDLE state
          wait_counter<='0;
          write_en<=1'b0;
          hsel_samp<=s_ahb.i_hsel;                                                                         //Sampled s_ahb.i_hsel
        end

        default: begin
          s_ahb.o_hresp<=1'b0;                                                                         //OKAY response is issued
          
          if (s_ahb.i_hreadyin) begin
            hwrite_samp<=s_ahb.i_hwrite;                                                               //Sampled s_ahb.i_hwrite
            haddr_samp<={{SLAVE_SELECT_BITS{1'b0}},s_ahb.i_haddr[REGISTER_SELECT_BITS-1:1]};           //Sampled s_ahb.i_haddr
            hsize_samp<=s_ahb.i_hsize;                                                                 //Sampled s_ahb.i_hsize  
            hsel_samp<=s_ahb.i_hsel;                                                                       //Sampled s_ahb.i_hsel
            if (s_ahb.i_hwrite==1'b1)
              hwdata_samp<=s_ahb.i_hwdata;                                                             //Sampled s_ahb.i_hwdata
          end 

          if ((s_ahb.i_hwrite)&&(wait_counter==0)||((hwrite_samp)&&(wait_counter>0))) begin            //Write transfer - considers s_ahb.i_hwrite only for the first cycle (see previous comments on the sampled packet)  	
            if (wait_counter<$bits(wait_counter)'(WAIT_WRITE)) begin
              s_ahb.o_hreadyout<=1'b0;
              wait_counter<=wait_counter+$bits(wait_counter)'(1);
              write_en<=1'b0;
            end
            else begin
              s_ahb.o_hreadyout<=1'b1;
              wait_counter<='0;
              write_en<=1'b1;
            end
          end
          else begin                                                                             //Read transfer
            if (wait_counter<$bits(wait_counter)'(WAIT_READ)) begin
              s_ahb.o_hreadyout<=1'b0;
              wait_counter<=wait_counter+$bits(wait_counter)'(1);
              write_en<=1'b0;
            end
            else begin
              s_ahb.o_hreadyout<=1'b1;
              wait_counter<='0;
              write_en<=1'b0;
            end
          end
        end
      endcase
    else begin
      s_ahb.o_hreadyout<=1'b1;
      hsel_samp<=1'b0;
    end

  //Execute the 'write' transfer: 'write_en' rises to logic high when the data is ready to be stored into the slave memory
  //Write operation follows big endian: MSB byte is stored in haddr and LSB byte is haddr+x
  always @(posedge i_hclk or negedge i_hreset)
    if (!i_hreset)
      mem<='0;                                           //Memory is initialized to all zeros
    else 
      if ((s_ahb.o_hreadyout)&&(write_en)&&(hsel_samp))
        case (hsize_samp)
          BYTE : mem[haddr_samp]<=s_ahb.i_hwdata[31:24];

          HALFWORD : begin
            mem[haddr_samp]<=s_ahb.i_hwdata[31:24];
            mem[haddr_samp+1]<=s_ahb.i_hwdata[23:16];
          end

          WORD : begin 
            mem[haddr_samp]<=s_ahb.i_hwdata[31:24];
            mem[haddr_samp+1]<=s_ahb.i_hwdata[23:16];
            mem[haddr_samp+2]<=s_ahb.i_hwdata[15:8];
            mem[haddr_samp+3]<=s_ahb.i_hwdata[7:0];
          end
        endcase

  //Execute the 'read' transfer
  //HRADATA is a continious assignment and not a synchronized signal - represnts the slave's internal calculation delay. This also solves the read-after-write issue since HRDATA is sampled by the master at the next positive edge (with hready high).
  //For additional details and power-related consideration please see attached documentation. 
  always @(*)
    if (hwrite_samp==1'b0)
      case (hsize_samp)
        BYTE : begin 
          s_ahb.o_hrdata[31:24]= mem[haddr_samp];
          s_ahb.o_hrdata[23:0]='0;
        end

        HALFWORD : begin
          s_ahb.o_hrdata[31:24]= mem[haddr_samp];
          s_ahb.o_hrdata[23:16]= mem[haddr_samp+1];
          s_ahb.o_hrdata[15:0]='0;
        end

        WORD : begin
          s_ahb.o_hrdata[31:24]= mem[haddr_samp];
          s_ahb.o_hrdata[23:16]= mem[haddr_samp+1];
          s_ahb.o_hrdata[15:8]= mem[haddr_samp+2];
          s_ahb.o_hrdata[7:0]= mem[haddr_samp+3];
        end
      endcase

endmodule
`end_keywords

`default_nettype wire  // restore implicit data types
