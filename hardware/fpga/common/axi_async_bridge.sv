//
// Asynchronous AXI->AXI bridge. This safely transfers AXI requests and
// responses between two clock domains.
//

module axi_async_bridge
    #(parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32)

    (input reset,

    // Slave Interface (from a master)
  input clk_s,
    axi4_interface.slave        axi_bus_s,

    // Master Interface (to a slave)
  input clk_m,
    axi4_interface.master       axi_bus_m);

    localparam CONTROL_FIFO_LENGTH = 2;    // requirement of async_fifo
    localparam DATA_FIFO_LENGTH = 8;

    //
    // Write adress from master->slave
    //
    logic write_adress_full;
    logic write_adress_empty;

    async_fifo #(ADDR_WIDTH + 8, CONTROL_FIFO_LENGTH) write_adress_fifo(
        .reset(reset),
        .write_clock(clk_s),
        .write_enable(!write_adress_full && axi_bus_s.m_awvalid),
        .write_data({axi_bus_s.m_awadr, axi_bus_s.m_awlen}),
        .full(write_adress_full),
        .read_clock(clk_m),
        .read_enable(!write_adress_empty && axi_bus_m.s_awready),
        .read_data({axi_bus_m.m_awadr, axi_bus_m.m_awlen}),
        .empty(write_adress_empty));

    assign axi_bus_s.s_awready = !write_adress_full;
    assign axi_bus_m.m_awvalid = !write_adress_empty;

    //
    // Write data from master->slave
    //
    logic write_data_full;
    logic write_data_empty;

    async_fifo #(DATA_WIDTH + 1, DATA_FIFO_LENGTH) write_data_fifo(
        .reset(reset),
        .write_clock(clk_s),
        .write_enable(!write_data_full && axi_bus_s.m_wvalid),
        .write_data({axi_bus_s.m_wdata, axi_bus_s.m_wlast}),
        .full(write_data_full),
        .read_clock(clk_m),
        .read_enable(!write_data_empty && axi_bus_m.s_wready),
        .read_data({axi_bus_m.m_wdata, axi_bus_m.m_wlast}),
        .empty(write_data_empty));

    assign axi_bus_s.s_wready = !write_data_full;
    assign axi_bus_m.m_wvalid = !write_data_empty;

    //
    // Write response from slave->master
    //
    logic write_response_full;
    logic write_response_empty;

    async_fifo #(1, CONTROL_FIFO_LENGTH) write_response_fifo(
        .reset(reset),
        .write_clock(clk_m),
        .write_enable(!write_response_full && axi_bus_m.s_bvalid),
        .write_data(1'b0),    // XXX pipe through actual error code
        .full(write_response_full),
        .read_clock(clk_s),
        .read_enable(!write_response_empty && axi_bus_s.m_bready),
        .read_data(/* unconnected */),
        .empty(write_response_empty));

    assign axi_bus_s.s_bvalid = !write_response_empty;
    assign axi_bus_m.m_bready = !write_response_full;

    //
    // Read adress from master->slave
    //
    logic read_adress_full;
    logic read_adress_empty;

    async_fifo #(ADDR_WIDTH + 8, CONTROL_FIFO_LENGTH) read_adress_fifo(
        .reset(reset),
        .write_clock(clk_s),
        .write_enable(!read_adress_full && axi_bus_s.m_arvalid),
        .write_data({axi_bus_s.m_aradr, axi_bus_s.m_arlen}),
        .full(read_adress_full),
        .read_clock(clk_m),
        .read_enable(!read_adress_empty && axi_bus_m.s_arready),
        .read_data({axi_bus_m.m_aradr, axi_bus_m.m_arlen}),
        .empty(read_adress_empty));

    assign axi_bus_s.s_arready = !read_adress_full;
    assign axi_bus_m.m_arvalid = !read_adress_empty;

    //
    // Read data from slave->master
    //
    logic read_data_full;
    logic read_data_empty;

    async_fifo #(DATA_WIDTH, DATA_FIFO_LENGTH) read_data_fifo(
        .reset(reset),
        .write_clock(clk_m),
        .write_enable(!read_data_full && axi_bus_m.s_rvalid),
        .write_data(axi_bus_m.s_rdata),
        .full(read_data_full),
        .read_clock(clk_s),
        .read_enable(!read_data_empty && axi_bus_s.m_rready),
        .read_data(axi_bus_s.s_rdata),
        .empty(read_data_empty));

    assign axi_bus_m.m_rready = !read_data_full;
    assign axi_bus_s.s_rvalid = !read_data_empty;
endmodule
