/******************************************************************************
 *
 * taxi_ahbl_if.sv
 *
 ******************************************************************************/
`begin_keywords "1800-2012"
`default_nettype none  // turn off implicit data types

interface taxi_ahbl_if #(
                         parameter ADDR_WIDTH = 32,
                         parameter DATA_WIDTH = 32
                         )
  (
    input wire i_hclk,
    input wire i_hreset
  );

  
  logic                  i_hsel;     
  logic [ADDR_WIDTH-1:0] i_haddr;    
  logic                  i_hwrite;   
  logic [2:0]            i_hsize;    
  logic [1:0]            i_htrans;   
  logic                  i_hreadyin; 
  logic [DATA_WIDTH-1:0] i_hwdata;   
  logic                  o_hreadyout; 
  logic                  o_hresp;     
  logic [DATA_WIDTH-1:0] o_hrdata;   

  // ========= Clocking blocks =========
  clocking cb_mon @(posedge i_hclk);
    input  #1step i_hreset;
    input  #1step i_hsel, i_haddr, i_hwrite, i_hsize, i_htrans, i_hreadyin;
    input  #1step i_hwdata, o_hrdata, o_hreadyout, o_hresp;
  endclocking

  clocking cb_drv @(posedge i_hclk);
    input  #1step i_hreset;
    input  #1step o_hreadyout, o_hresp, o_hrdata;
    output #0     i_hsel, i_haddr, i_hwrite, i_hsize, i_htrans, i_hreadyin;
    output #0     i_hwdata;
  endclocking

  // ========= Modports =========
  modport MON (clocking cb_mon);

  modport DRV (clocking cb_drv);
  // Master Side - This modport COMES from a single master
  //***************************************
  modport slv
    (     
     input  i_hsel,
            i_haddr , 
            i_hwrite , 
            i_hsize , 
            i_htrans , 
            i_hreadyin , 
            i_hwdata,
     
     output o_hreadyout,
            o_hresp,
            o_hrdata

     );

  // Slave Side - This slave port GOES to a multiple slaves
  //***************************************
  modport mst
    (
     output i_hsel,
            i_haddr , 
            i_hwrite , 
            i_hsize , 
            i_htrans , 
            i_hreadyin , 
            i_hwdata,
    
     input  o_hreadyout,
            o_hresp,
            o_hrdata
     );

endinterface


`end_keywords

`default_nettype wire  // restore implicit data types
