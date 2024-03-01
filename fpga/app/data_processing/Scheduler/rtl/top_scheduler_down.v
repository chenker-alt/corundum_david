module top_scheduler_down #(
    // Ethernet interface configuration
    parameter IF_COUNT = 4,
    parameter IF_COUNT_DOWN_RX = 3,
    parameter IF_COUNT_DOWN_TX = 1,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // Parser/Mat/deparser configuration
    parameter META_DATA_WIDTH_MAX=272,
    parameter COUNT_META_DATA_MAX=(META_DATA_WIDTH_MAX/AXIS_DATA_WIDTH)+1,
    parameter COUNTER_WIDTH= $clog2(COUNT_META_DATA_MAX+1),

    parameter BUFFER_DATA_WIDTH=COUNT_META_DATA_MAX*AXIS_DATA_WIDTH,


    // State
    parameter STATE_WIDTH           = 3,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5
)
(
    // System (internal at interface module)
    input wire clk,
    input wire rst,

    /*
     * Ethernet (internal at interface module)
     */
    input wire  [IF_COUNT_DOWN_RX*AXIS_DATA_WIDTH-1:0]  s_axis_top_scheduler_down_tdata,
    input wire  [IF_COUNT_DOWN_RX*AXIS_KEEP_WIDTH-1:0]  s_axis_top_scheduler_down_tkeep,
    input wire  [IF_COUNT_DOWN_RX-1:0]                  s_axis_top_scheduler_down_tvalid,
    output wire [IF_COUNT_DOWN_RX-1:0]                  s_axis_top_scheduler_down_tready,
    input wire  [IF_COUNT_DOWN_RX-1:0]                  s_axis_top_scheduler_down_tlast,

    output wire [IF_COUNT_DOWN_TX*AXIS_DATA_WIDTH-1:0]  m_axis_top_scheduler_down_tdata,
    output wire [IF_COUNT_DOWN_TX*AXIS_KEEP_WIDTH-1:0]  m_axis_top_scheduler_down_tkeep,
    output wire [IF_COUNT_DOWN_TX-1:0]                  m_axis_top_scheduler_down_tvalid,
    input wire  [IF_COUNT_DOWN_TX-1:0]                  m_axis_top_scheduler_down_tready,
    output wire [IF_COUNT_DOWN_TX-1:0]                  m_axis_top_scheduler_down_tlast,

    /*
     * AXI-Lite input/output
     */

    input wire w_enable_dp,
    input wire [32-1:0]w_configurable_ipv4_address,
    input wire w_rst_drop_counter,
    output wire [IF_COUNT_DOWN_RX*32-1:0] w_drop_counter

);
    // //wire axil register interface

    // wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]     w_reg_wr_addr;
    // wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]     w_reg_wr_data;
    // wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]     w_reg_wr_strb;
    // wire                                    w_reg_wr_en;
    // wire                                    w_reg_wr_wait;
    // wire                                    w_reg_wr_ack;
    // wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]     w_reg_rd_addr;
    // wire                                    w_reg_rd_en;
    // wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]     w_reg_rd_data;
    // wire                                    w_reg_rd_wait;
    // wire                                    w_reg_rd_ack;

    // //wire axil register
    // wire [31:0] w_configurable_ipv4_address;
    // wire w_enable_dp;
    // wire w_rst_drop_counter;

    // wire [31:0] w_drop_counter[2:0];

    // axil_reg_if #(
    // .DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    // .ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
    // .STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH)
    // )
    // axil_reg_if_inst(
    //     .clk(clk),
    //     .rst(rst),

    //     .s_axil_awaddr(s_axil_awaddr),
    //     .s_axil_awprot(s_axil_awprot),
    //     .s_axil_awvalid(s_axil_awvalid),
    //     .s_axil_awready(s_axil_awready),
    //     .s_axil_wdata(s_axil_wdata),
    //     .s_axil_wstrb(s_axil_wstrb),
    //     .s_axil_wvalid(s_axil_wvalid),
    //     .s_axil_wready(s_axil_wready),
    //     .s_axil_bresp(s_axil_bresp),
    //     .s_axil_bvalid(s_axil_bvalid),
    //     .s_axil_bready(s_axil_bready),
    //     .s_axil_araddr(s_axil_araddr),
    //     .s_axil_arprot(s_axil_arprot),
    //     .s_axil_arvalid(s_axil_arvalid),
    //     .s_axil_arready(s_axil_arready),
    //     .s_axil_rdata(s_axil_rdata),
    //     .s_axil_rresp(s_axil_rresp),
    //     .s_axil_rvalid(s_axil_rvalid),
    //     .s_axil_rready(s_axil_rready),

    //     .reg_wr_addr(w_reg_wr_addr),
    //     .reg_wr_data(w_reg_wr_data),
    //     .reg_wr_strb(w_reg_wr_strb),
    //     .reg_wr_en(w_reg_wr_en),
    //     .reg_wr_wait(w_reg_wr_wait),
    //     .reg_wr_ack(w_reg_wr_ack),
    //     .reg_rd_addr(w_reg_rd_addr),
    //     .reg_rd_en(w_reg_rd_en),
    //     .reg_rd_data(w_reg_rd_data),
    //     .reg_rd_wait(w_reg_rd_wait),
    //     .reg_rd_ack(w_reg_rd_ack)

    // );

    // reg reg_wr_ack_reg = 1'b0;
    // reg [AXIL_APP_CTRL_DATA_WIDTH-1:0] reg_rd_data_reg = {AXIL_APP_CTRL_DATA_WIDTH{1'b0}};
    // reg reg_rd_ack_reg = 1'b0;

    // reg [31:0] reg_configurable_ipv4_address;
    // reg reg_enable_dp=1;
    // reg reg_rst_drop_counter;
    // wire [31:0] drop_counter;

    // assign w_reg_wr_wait = 1'b0;
    // assign w_reg_wr_ack = reg_wr_ack_reg;
    // assign w_reg_rd_data = reg_rd_data_reg;
    // assign w_reg_rd_wait = 1'b0;
    // assign w_reg_rd_ack = reg_rd_ack_reg;

    // assign w_enable_dp = reg_enable_dp;
    // assign w_configurable_ipv4_address = reg_configurable_ipv4_address;
    // assign w_rst_drop_counter = reg_rst_drop_counter;

    // always @(posedge clk) begin
    //     reg_wr_ack_reg <= 1'b0;
    //     reg_rd_data_reg <= {AXIL_APP_CTRL_DATA_WIDTH{1'b0}};
    //     reg_rd_ack_reg <= 1'b0;
    //     // write operation
    //     if (w_reg_wr_en && !reg_wr_ack_reg) begin
    //         reg_wr_ack_reg <= 1'b0;
    //         case (w_reg_wr_addr)
    //             16'h0100: reg_enable_dp <= w_reg_wr_data[0];
    //             16'h0104: reg_configurable_ipv4_address <= w_reg_wr_data;
    //             16'h0200: reg_rst_drop_counter <= w_reg_wr_data[0];
    //             default : reg_wr_ack_reg <= 1'b0;
    //         endcase
    //     end

    //     // read operation
    //     if (w_reg_rd_en && !reg_rd_ack_reg) begin
    //         reg_rd_ack_reg <= 1'b1;
    //         case (w_reg_rd_addr)
    //             16'h0100: reg_rd_data_reg <= {31'b0, reg_enable_dp};
    //             16'h0104: reg_rd_data_reg <= reg_configurable_ipv4_address;
    //             16'h0200: reg_rd_data_reg <= {31'b0, reg_rst_drop_counter};

    //             16'h0204: reg_rd_data_reg <= w_drop_counter[0];
    //             16'h0208: reg_rd_data_reg <= w_drop_counter[1];
    //             16'h020C: reg_rd_data_reg <= w_drop_counter[2];
    //             default: reg_rd_ack_reg <= 1'b0;
    //         endcase
    //     end
    //     if (rst) begin
    //         reg_wr_ack_reg <= 1'b0;
    //         reg_rd_ack_reg <= 1'b0;
    //     end
    // end
    wire [IF_COUNT_DOWN_RX*AXIS_DATA_WIDTH-1:0] w_axis_packet_dispatcher_crossbar_tdata;
    wire [IF_COUNT_DOWN_RX*AXIS_KEEP_WIDTH -1:0] w_axis_packet_dispatcher_crossbar_tkeep;
    wire [IF_COUNT_DOWN_RX-1:0] w_axis_packet_dispatcher_crossbar_tvalid;
    wire [IF_COUNT_DOWN_RX-1:0] w_axis_packet_dispatcher_crossbar_tready;
    wire [IF_COUNT_DOWN_RX-1:0] w_axis_packet_dispatcher_crossbar_tlast;
    wire [IF_COUNT_DOWN_RX*AXIS_DEST_WIDTH-1:0] w_axis_packet_dispatcher_crossbar_tdest;

    genvar i;
    generate
        for (i = 0; i < IF_COUNT_DOWN_RX; i = i + 1) begin : gen_packet_dispatchers

            top_packet_dispatcher #(
            .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
            .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
            .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

            .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
            .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),
            .AXIL_APP_CTRL_STRB_WIDTH(AXIL_APP_CTRL_STRB_WIDTH),

            .META_DATA_WIDTH_MAX(META_DATA_WIDTH_MAX),
            .COUNT_META_DATA_MAX(COUNT_META_DATA_MAX),
            .COUNTER_WIDTH(COUNTER_WIDTH),
            .BUFFER_DATA_WIDTH(BUFFER_DATA_WIDTH),

            .STATE_WIDTH(STATE_WIDTH),
            .IDLE(IDLE),
            .PARSE_DATA(PARSE_DATA),
            .CONTROL(CONTROL),
            .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
            .SEND_REMAIN(SEND_REMAIN),
            .DROP(DROP)
            
            ) top_packet_dispatcher_inst (
                .clk(clk),
                .rst(rst),

                .s_axis_top_packet_dispatcher_tdata(s_axis_top_scheduler_down_tdata[AXIS_DATA_WIDTH+AXIS_DATA_WIDTH*i-1-:AXIS_DATA_WIDTH]),
                .s_axis_top_packet_dispatcher_tkeep(s_axis_top_scheduler_down_tkeep[AXIS_KEEP_WIDTH+AXIS_KEEP_WIDTH*i-1-:AXIS_KEEP_WIDTH]),
                .s_axis_top_packet_dispatcher_tvalid(s_axis_top_scheduler_down_tvalid[i]),
                .s_axis_top_packet_dispatcher_tready(s_axis_top_scheduler_down_tready[i]),
                .s_axis_top_packet_dispatcher_tlast(s_axis_top_scheduler_down_tlast[i]),

                .m_axis_top_packet_dispatcher_tdata(w_axis_packet_dispatcher_crossbar_tdata[AXIS_DATA_WIDTH+AXIS_DATA_WIDTH*i-1-:AXIS_DATA_WIDTH]),
                .m_axis_top_packet_dispatcher_tkeep(w_axis_packet_dispatcher_crossbar_tkeep[AXIS_KEEP_WIDTH+AXIS_KEEP_WIDTH*i-1-:AXIS_KEEP_WIDTH]),
                .m_axis_top_packet_dispatcher_tvalid(w_axis_packet_dispatcher_crossbar_tvalid[i]),
                .m_axis_top_packet_dispatcher_tready(w_axis_packet_dispatcher_crossbar_tready[i]),
                .m_axis_top_packet_dispatcher_tlast(w_axis_packet_dispatcher_crossbar_tlast[i]),
                .m_axis_top_packet_dispatcher_tdest(w_axis_packet_dispatcher_crossbar_tdest[AXIS_DEST_WIDTH+AXIS_DEST_WIDTH*i-1-:AXIS_DEST_WIDTH]),

                .w_enable_dp(w_enable_dp),
                .w_configurable_ipv4_address(w_configurable_ipv4_address),
                .w_rst_drop_counter(w_rst_drop_counter),
                .w_drop_counter(w_drop_counter[32+32*i-1-:32])
            );
        end
    endgenerate

    wire [AXIS_DATA_WIDTH-1:0] w_axis_crossbar_fifo0_tdata;
    wire [AXIS_KEEP_WIDTH -1:0] w_axis_crossbar_fifo0_tkeep;
    wire w_axis_crossbar_fifo0_tvalid;
    wire w_axis_crossbar_fifo0_tready;
    wire w_axis_crossbar_fifo0_tlast;
    wire [AXIS_DEST_WIDTH-1:0] w_axis_crossbar_fifo0_tdest;

    wire [AXIS_DATA_WIDTH-1:0] w_axis_crossbar_fifo1_tdata;
    wire [AXIS_KEEP_WIDTH -1:0] w_axis_crossbar_fifo1_tkeep;
    wire w_axis_crossbar_fifo1_tvalid;
    wire w_axis_crossbar_fifo1_tready;
    wire w_axis_crossbar_fifo1_tlast;
    wire [AXIS_DEST_WIDTH-1:0] w_axis_crossbar_fifo1_tdest;

    wire [AXIS_DATA_WIDTH-1:0] w_axis_crossbar_fifo2_tdata;
    wire [AXIS_KEEP_WIDTH -1:0] w_axis_crossbar_fifo2_tkeep;
    wire w_axis_crossbar_fifo2_tvalid;
    wire w_axis_crossbar_fifo2_tready;
    wire w_axis_crossbar_fifo2_tlast;
    wire [AXIS_DEST_WIDTH-1:0] w_axis_crossbar_fifo2_tdest;

    axi_stream_crossbar #(
    .IF_COUNT_DOWN_RX(IF_COUNT_DOWN_RX),

    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH)
    )
    axi_stream_crossbar_inst (

        .clk(clk),
        .rst(rst),

        .s_axis_crossbar_tdata(w_axis_packet_dispatcher_crossbar_tdata),
        .s_axis_crossbar_tkeep(w_axis_packet_dispatcher_crossbar_tkeep),
        .s_axis_crossbar_tvalid(w_axis_packet_dispatcher_crossbar_tvalid),
        .s_axis_crossbar_tready(w_axis_packet_dispatcher_crossbar_tready),
        .s_axis_crossbar_tlast(w_axis_packet_dispatcher_crossbar_tlast),
        .s_axis_crossbar_tdest(w_axis_packet_dispatcher_crossbar_tdest),

        .m_axis_crossbar_fifo0_tdata(w_axis_crossbar_fifo0_tdata),
        .m_axis_crossbar_fifo0_tkeep(w_axis_crossbar_fifo0_tkeep),
        .m_axis_crossbar_fifo0_tvalid(w_axis_crossbar_fifo0_tvalid),
        .m_axis_crossbar_fifo0_tready(w_axis_crossbar_fifo0_tready),
        .m_axis_crossbar_fifo0_tlast(w_axis_crossbar_fifo0_tlast),

        .m_axis_crossbar_fifo1_tdata(w_axis_crossbar_fifo1_tdata),
        .m_axis_crossbar_fifo1_tkeep(w_axis_crossbar_fifo1_tkeep),
        .m_axis_crossbar_fifo1_tvalid(w_axis_crossbar_fifo1_tvalid),
        .m_axis_crossbar_fifo1_tready(w_axis_crossbar_fifo1_tready),
        .m_axis_crossbar_fifo1_tlast(w_axis_crossbar_fifo1_tlast),

        .m_axis_crossbar_fifo2_tdata(w_axis_crossbar_fifo2_tdata),
        .m_axis_crossbar_fifo2_tkeep(w_axis_crossbar_fifo2_tkeep),
        .m_axis_crossbar_fifo2_tvalid(w_axis_crossbar_fifo2_tvalid),
        .m_axis_crossbar_fifo2_tready(w_axis_crossbar_fifo2_tready),
        .m_axis_crossbar_fifo2_tlast(w_axis_crossbar_fifo2_tlast)

    );

    top_priority_FIFO #(
    .IF_COUNT_DOWN_RX(IF_COUNT_DOWN_RX),
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),
    .AXIS_DEST_WIDTH(AXIS_DEST_WIDTH),

    .STATE_WIDTH(STATE_WIDTH),
    .IDLE(IDLE),
    .PARSE_DATA(PARSE_DATA),
    .CONTROL(CONTROL),
    .SEND_ANALYSED_DATA(SEND_ANALYSED_DATA),
    .SEND_REMAIN(SEND_REMAIN),
    .DROP(DROP)
    )
    top_priority_FIFO_inst(
        .clk(clk),
        .rst(clk),

        .s_axis_priority_fifo0_tdata(w_axis_crossbar_fifo0_tdata),
        .s_axis_priority_fifo0_tkeep(w_axis_crossbar_fifo0_tkeep),
        .s_axis_priority_fifo0_tvalid(w_axis_crossbar_fifo0_tvalid),
        .s_axis_priority_fifo0_tready(w_axis_crossbar_fifo0_tready),
        .s_axis_priority_fifo0_tlast(w_axis_crossbar_fifo0_tlast),

        .s_axis_priority_fifo1_tdata(w_axis_crossbar_fifo1_tdata),
        .s_axis_priority_fifo1_tkeep(w_axis_crossbar_fifo1_tkeep),
        .s_axis_priority_fifo1_tvalid(w_axis_crossbar_fifo1_tvalid),
        .s_axis_priority_fifo1_tready(w_axis_crossbar_fifo1_tready),
        .s_axis_priority_fifo1_tlast(w_axis_crossbar_fifo1_tlast),

        .s_axis_priority_fifo2_tdata(w_axis_crossbar_fifo2_tdata),
        .s_axis_priority_fifo2_tkeep(w_axis_crossbar_fifo2_tkeep),
        .s_axis_priority_fifo2_tvalid(w_axis_crossbar_fifo2_tvalid),
        .s_axis_priority_fifo2_tready(w_axis_crossbar_fifo2_tready),
        .s_axis_priority_fifo2_tlast(w_axis_crossbar_fifo2_tlast),

        .m_axis_priority_fifo_tdata(m_axis_top_scheduler_down_tdata),
        .m_axis_priority_fifo_tkeep(m_axis_top_scheduler_down_tkeep),
        .m_axis_priority_fifo_tvalid(m_axis_top_scheduler_down_tvalid),
        .m_axis_priority_fifo_tready(m_axis_top_scheduler_down_tready),
        .m_axis_priority_fifo_tlast(m_axis_top_scheduler_down_tlast)
    );
endmodule
