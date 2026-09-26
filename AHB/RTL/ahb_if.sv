import ahb_define_pkg::*;

interface ahb_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(input logic hclk, input logic hreset_n);
    // Global signals
    // logic                    hclk;
    // logic                    hreset_n;

    logic                     i_enb;
    logic [DATA_WIDTH-1:0]    i_data;
    logic                     i_write;
    logic [ADDR_WIDTH-1:0]    i_addr;
    logic                     i_wrap_en;
    burst_t                   i_burst_type;
    hsize_t                   i_data_size;
    logic                     i_busy;

    // Wait signals input to the slave
    logic i_wait_1;
    logic i_wait_2;
    logic i_wait_3;
    logic i_wait_4;
    
    // Output of Master (Input of Slave)
    logic [ADDR_WIDTH-1:0]   haddr;
    logic                    hwrite;
    logic [2:0]              hsize;
    logic [2:0]              hburst;
    htrans_t                 htrans;
    logic                    hmastlock;
    logic [3:0]              hprot;
    logic                    hsel;

    
    // Write Data
    logic [DATA_WIDTH-1:0]   hwdata;

   
    // Output of Slave (Input of Master)
    logic [DATA_WIDTH-1:0]   hrdata;
    logic                    hready;
    logic                    hresp;

    bit master_drvstart, master_monstart;
    bit slave_drvstart, slave_monstart;
    modport master (
        input  hclk,
        input  hreset_n,
        input  i_enb,
        input  i_data,
        input  i_write,
        input  i_addr,
        input  i_wrap_en,
        input  i_burst_type,
        input  i_data_size,
        input  i_busy,

        input  hrdata,
        input  hready,
        input  hresp,

        output haddr,
        output hwdata,
        output hwrite,
        output hsize,
        output hburst,
        output htrans,
        output hmastlock,
        output hprot,
        import master_reset_signals,
                drive_single_write_trans,
                drive_single_read_trans,
                drive_incr_write_trans,
                drive_incr_read_trans,
                drive_incr4_write_trans,
                drive_incr4_read_trans,
                drive_incr8_write_trans,
                drive_incr8_read_trans,
                drive_incr16_write_trans,
                drive_incr16_read_trans,
                drive_wrap4_write_trans,
                drive_wrap4_read_trans,
                drive_wrap8_write_trans,
                drive_wrap8_read_trans,
                drive_wrap16_write_trans,
                drive_wrap16_read_trans,
                drive_incr_wait_write_trans,
                drive_incr_wait_read_trans,
                drive_wrap_wait_write_trans,
                drive_wrap_wait_read_trans,
                ahb_master_burst_collector,
                ahb_master_single_collector,
        input   master_monstart,
                master_drvstart
    );

    modport slave (
        input  hclk,
        input  hreset_n,

        input  haddr,
        input  hwdata,
        input  hwrite,
        input  hsize,
        input  hburst,
        input  htrans,
        input  hmastlock,
        input  hprot,
        input  hsel,

        output hrdata,
        output hready,
        output hresp,
        import slave_reset_signals, 
               ahb_slave_burst_collector,
               ahb_slave_single_collector,
        input  slave_drvstart,
               slave_monstart
    );


    task master_reset_signals();
        @(negedge hreset_n);
        i_enb       = 0;
        i_data      = 0;
        i_write     = 0;
        i_addr      = 32'h0000_0000;
        i_wrap_en   = 0;
        i_burst_type= SINGLE;
        i_data_size = HSIZE_WORD;
        i_busy      = 0;
        i_wait_1    = 0;
        i_wait_2    = 0;
        i_wait_3    = 0;
        i_wait_4    = 0;
    endtask: master_reset_signals


    task slave_reset_signals();

    endtask: slave_reset_signals

    task drive_single_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
       
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_single_write_trans

    task drive_single_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );

        // SINGLE READ transaction
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_single_read_trans


    task drive_incr_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(4) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        master_drvstart <= 0;
    endtask: drive_incr_write_trans

    task drive_incr_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_busy  <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(4) @(posedge hclk);
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_incr_read_trans

    task drive_incr4_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(3) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_write <= 0;
        master_drvstart = 0;
    endtask: drive_incr4_write_trans

    task drive_incr4_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_busy  <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(4) @(posedge hclk);
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_incr4_read_trans

    task drive_incr8_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(7) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_write <= 0;
        master_drvstart = 0;
    endtask: drive_incr8_write_trans

    task drive_incr8_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_busy  <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(8) @(posedge hclk);
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_incr8_read_trans

    task drive_incr16_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(15) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_write <= 0;
        master_drvstart = 0;
    endtask: drive_incr16_write_trans

    task drive_incr16_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_busy  <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(16) @(posedge hclk);
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_incr16_read_trans

    task drive_wrap4_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(3) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_wrap_en <= 0;
        i_write <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap4_write_trans

    task drive_wrap4_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(4) @(posedge hclk);
        @(posedge hclk);
        i_wrap_en <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap4_read_trans

    task drive_wrap8_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(7) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_wrap_en <= 0;
        i_write <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap8_write_trans

    task drive_wrap8_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(8) @(posedge hclk);
        @(posedge hclk);
        i_wrap_en <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap8_read_trans


    task drive_wrap16_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(15) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_wrap_en <= 0;
        i_write <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap16_write_trans

    task drive_wrap16_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        // @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(16) @(posedge hclk);
        @(posedge hclk);
        i_wrap_en <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_wrap16_read_trans

    task drive_incr_wait_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(7) @(posedge hclk) i_data <= i_data + 1;
        i_wait_1 <= 1;
        repeat(2)@(posedge hclk)
        i_wait_1 <= 0;
        repeat(8) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_write <= 0;
        master_drvstart = 0;
    endtask: drive_incr_wait_write_trans

    task drive_incr_wait_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_write <= 0;
        i_busy  <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(6) @(posedge hclk);
        i_wait_1 <= 1;
        repeat(2)@(posedge hclk)
        i_wait_1 <= 0;
        repeat(10) @(posedge hclk);
        @(posedge hclk);
        master_drvstart = 0;
    endtask: drive_incr_wait_read_trans


    task drive_wrap_wait_write_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                bit [DATA_WIDTH-1:0]    data,
                hsize_t                 hsize 
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 1;
        i_addr  <= address;
        i_data_size<= hsize;
        i_burst_type <= burst_type;
        @(posedge hclk);
        i_enb   <= 0;
        @(posedge hclk);
        i_data  <= data;
        repeat(5) @(posedge hclk) i_data <= i_data + 1;
        i_wait_1 <= 1;
        repeat(2)@(posedge hclk)
        i_wait_1 <= 0;
        repeat(10) @(posedge hclk) i_data <= i_data + 1;
        @(posedge hclk);
        i_wrap_en <= 0;
        i_write <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask

    task drive_wrap_wait_read_trans(
        input   burst_t                 burst_type,
                bit [ADDR_WIDTH-1:0]    address,
                hsize_t                 hsize
    );
        @(posedge hclk);
        i_busy  <= 1;
        @(posedge hclk);
        master_drvstart = 1;
        i_enb   <= 1;
        i_busy  <= 0;
        i_wrap_en <= 1;
        i_write <= 0;
        i_addr  <= address;
        i_burst_type <= burst_type;
        i_data_size <= hsize;
        @(posedge hclk);
        i_enb   <= 0;
        repeat(6) @(posedge hclk);
        i_wait_1 <= 1;
        repeat(2)@(posedge hclk)
        i_wait_1 <= 0;
        repeat(10) @(posedge hclk);
        @(posedge hclk);
        i_wrap_en <= 0;
        @(posedge hclk);
        master_drvstart = 0;
    endtask


    bit master_first_sample = 1;
    bit slave_first_sample  = 1;
    bit master_wait_transaction = 0;
    bit slave_wait_transaction  = 0;

    // Reset lại flag khi có sườn xuống của master_drvstart
    always @(negedge master_drvstart) begin
        master_first_sample = 1;
        slave_first_sample  = 1;
    end

    task ahb_master_burst_collector(
        output bit                  write_en,
        output burst_t              burst_type,
        output hsize_t              hsize,
        output bit [ADDR_WIDTH-1:0] address,
        output bit [DATA_WIDTH-1:0] data_in
    );
        if (master_wait_transaction) begin
            if (master_drvstart == 1) begin
                @(negedge master_drvstart);
            end
            master_wait_transaction = 0;
        end
        wait(master_drvstart == 1);
        if (master_first_sample) begin
            // @(posedge master_drvstart);   // chờ sườn lên
            @(posedge hclk);
            @(posedge hclk iff (hready));
            master_monstart = 1;
            write_en   = i_write;
            burst_type = i_burst_type;
            hsize      = i_data_size;
            address    = tb_ahb_top.uut.master_if.haddr;
            @(posedge hclk);
            data_in    = i_data;
            master_first_sample = 0;      // kéo về 0 sau sample đầu tiên
            master_monstart = 0;
            if (burst_type == SINGLE) begin
                master_wait_transaction = 1;
            end
            $display("Master First time Sample");
        end else begin
            if(!master_first_sample)    begin
                wait(hready);
                master_monstart = 1;
                burst_type = i_burst_type;
                hsize      = i_data_size;
                address    = tb_ahb_top.uut.master_if.haddr;
                @(posedge hclk);
                data_in    = i_data;
                master_monstart = 0;
            end
        end
    endtask : ahb_master_burst_collector

    task ahb_slave_burst_collector(
        output bit [ADDR_WIDTH-1:0] address,
        output burst_t              burst_type,
        output hsize_t              hsize,
        output bit [DATA_WIDTH-1:0] data_write,
        output bit [DATA_WIDTH-1:0] data_read,
        output htrans_t             trans_type,
        output bit                  write,
        output bit                  resp
    );
        if (slave_wait_transaction) begin
            if (master_drvstart == 1) begin
                @(negedge master_drvstart);
            end
            slave_wait_transaction = 0;
        end
        wait(master_drvstart == 1);
        if (slave_first_sample) begin
            @(posedge hclk);
            @(posedge hclk iff (hready));
            slave_monstart = 1;
            address    = tb_ahb_top.uut.master_if.haddr;
            burst_type = tb_ahb_top.uut.master_if.hburst;
            hsize      = tb_ahb_top.uut.master_if.hsize;
            trans_type = tb_ahb_top.uut.master_if.htrans;
            write      = tb_ahb_top.uut.master_if.hwrite;
            @(posedge hclk);
            data_write = tb_ahb_top.uut.master_if.hwdata;
            data_read  = tb_ahb_top.uut.master_if.hrdata;
            resp       = hresp;
            slave_first_sample = 0;       // kéo về 0 sau sample đầu tiên
            slave_monstart = 0;
            if (burst_type == SINGLE) begin
                slave_wait_transaction = 1;
            end
            $display("Slave First time Sample");
        end else begin
            if(!(slave_monstart)) begin
                wait(hready);
                slave_monstart = 1;
                address    = tb_ahb_top.uut.master_if.haddr;
                burst_type = tb_ahb_top.uut.master_if.hburst;
                hsize      = tb_ahb_top.uut.master_if.hsize;
                trans_type = tb_ahb_top.uut.master_if.htrans;
                write      = tb_ahb_top.uut.master_if.hwrite;
                @(posedge hclk);
                data_write = tb_ahb_top.uut.master_if.hwdata;
                data_read  = tb_ahb_top.uut.master_if.hrdata;
                resp       = hresp;
                slave_monstart = 0;
            end
    end
    endtask : ahb_slave_burst_collector


    task ahb_master_single_collector(
        output bit                  write_en,
        output burst_t              burst_type,
        output hsize_t              hsize,
        output bit [ADDR_WIDTH-1:0] address,
        output bit [DATA_WIDTH-1:0] data_in
    );
        @(posedge master_drvstart);
        @(posedge hclk);
        @(posedge hclk iff (hready));
        master_monstart = 1;
        write_en   = i_write;
        burst_type = i_burst_type;
        hsize      = i_data_size;
        address    = tb_ahb_top.uut.master_if.haddr;
        @(posedge hclk);
        data_in    = i_data;
        master_monstart = 0;
    endtask: ahb_master_single_collector

    task ahb_slave_single_collector(
        output bit [ADDR_WIDTH-1:0] address,
        output burst_t              burst_type,
        output hsize_t              hsize,
        output bit [DATA_WIDTH-1:0] data_write,
        output bit [DATA_WIDTH-1:0] data_read,
        output htrans_t             trans_type,
        output bit                  write,
        output bit                  resp
    );
        @(posedge master_drvstart);
        @(posedge hclk);
        @(posedge hclk iff (hready));
        slave_monstart = 1;
        address    = tb_ahb_top.uut.master_if.haddr;
        burst_type = tb_ahb_top.uut.master_if.hburst;
        hsize      = tb_ahb_top.uut.master_if.hsize;
        trans_type = tb_ahb_top.uut.master_if.htrans;
        write      = tb_ahb_top.uut.master_if.hwrite;
        @(posedge hclk);
        data_write = tb_ahb_top.uut.master_if.hwdata;
        data_read  = tb_ahb_top.uut.master_if.hrdata;
        resp       = hresp;
        slave_monstart = 0;
    endtask: ahb_slave_single_collector

endinterface: ahb_if