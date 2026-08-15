import ahb_pkg::*;
module ahb_address_decoder #(
    parameter ADDR_WIDTH = 32
)
(
    ahb_if.master ahb,

    output logic       hsel_1,
    output logic       hsel_2,
    output logic       hsel_3,
    output logic       hsel_4,

    output logic [1:0] mux_select
);

logic transfer_valid;
logic [1:0] slave_index;
assign transfer_valid = (ahb.htrans != ahb_pkg::IDLE);

assign slave_index    = ahb.haddr[11:10];

assign hsel_1 = transfer_valid & (slave_index == 2'b00);
assign hsel_2 = transfer_valid & (slave_index == 2'b01);
assign hsel_3 = transfer_valid & (slave_index == 2'b10);
assign hsel_4 = transfer_valid & (slave_index == 2'b11);

// -------------------------------------------------------------------------
// Combinational mux select
// -------------------------------------------------------------------------
always_comb begin
    unique case (slave_index)
        2'b00: mux_select = 2'b00;
        2'b01: mux_select = 2'b01;
        2'b10: mux_select = 2'b10;
        2'b11: mux_select = 2'b11;
        default: mux_select = 2'b00;
    endcase
    end
endmodule