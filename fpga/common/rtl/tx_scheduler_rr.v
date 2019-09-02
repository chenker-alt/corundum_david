/*

Copyright 2019, The Regents of the University of California.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of The Regents of the University of California.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * Transmit scheduler (round-robin)
 */
module tx_scheduler_rr #
(
    // Width of AXI lite data bus in bits
    parameter AXIL_DATA_WIDTH = 32,
    // Width of AXI lite address bus in bits
    parameter AXIL_ADDR_WIDTH = 16,
    // Width of AXI lite wstrb (width of data bus in words)
    parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
    // AXI DMA length field width
    parameter AXI_DMA_LEN_WIDTH = 16,
    // Transmit request tag field width
    parameter REQ_TAG_WIDTH = 8,
    // Number of outstanding operations
    parameter OP_TABLE_SIZE = 16,
    // Queue index width
    parameter QUEUE_INDEX_WIDTH = 6,
    // Pipeline stages
    parameter PIPELINE = 2
)
(
    input  wire                          clk,
    input  wire                          rst,

    /*
     * Transmit request output (queue index)
     */
    output wire [QUEUE_INDEX_WIDTH-1:0]  m_axis_tx_req_queue,
    output wire [REQ_TAG_WIDTH-1:0]      m_axis_tx_req_tag,
    output wire                          m_axis_tx_req_valid,
    input  wire                          m_axis_tx_req_ready,

    /*
     * Transmit request status input
     */
    input  wire [AXI_DMA_LEN_WIDTH-1:0]  s_axis_tx_req_status_len,
    input  wire [REQ_TAG_WIDTH-1:0]      s_axis_tx_req_status_tag,
    input  wire                          s_axis_tx_req_status_valid,

    /*
     * Doorbell input
     */
    input  wire [QUEUE_INDEX_WIDTH-1:0]  s_axis_doorbell_queue,
    input  wire                          s_axis_doorbell_valid,

    /*
     * AXI-Lite slave interface
     */
    input  wire [AXIL_ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire [2:0]                    s_axil_awprot,
    input  wire                          s_axil_awvalid,
    output wire                          s_axil_awready,
    input  wire [AXIL_DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [AXIL_STRB_WIDTH-1:0]    s_axil_wstrb,
    input  wire                          s_axil_wvalid,
    output wire                          s_axil_wready,
    output wire [1:0]                    s_axil_bresp,
    output wire                          s_axil_bvalid,
    input  wire                          s_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire [2:0]                    s_axil_arprot,
    input  wire                          s_axil_arvalid,
    output wire                          s_axil_arready,
    output wire [AXIL_DATA_WIDTH-1:0]    s_axil_rdata,
    output wire [1:0]                    s_axil_rresp,
    output wire                          s_axil_rvalid,
    input  wire                          s_axil_rready,

    /*
     * Control
     */
    input  wire                          enable,
    output wire                          active
);

parameter QUEUE_COUNT = 2**QUEUE_INDEX_WIDTH;

parameter CL_OP_TABLE_SIZE = $clog2(OP_TABLE_SIZE);

parameter QUEUE_RAM_BE_WIDTH = 2;
parameter QUEUE_RAM_WIDTH = QUEUE_RAM_BE_WIDTH*8;

// bus width assertions
initial begin
    if (REQ_TAG_WIDTH < CL_OP_TABLE_SIZE) begin
        $error("Error: REQ_TAG_WIDTH insufficient for OP_TABLE_SIZE (instance %m)");
        $finish;
    end

    if (AXIL_DATA_WIDTH != 32) begin
        $error("Error: AXI lite interface width must be 32 (instance %m)");
        $finish;
    end

    if (AXIL_STRB_WIDTH * 8 != AXIL_DATA_WIDTH) begin
        $error("Error: AXI lite interface requires byte (8-bit) granularity (instance %m)");
        $finish;
    end

    if (AXIL_ADDR_WIDTH < QUEUE_INDEX_WIDTH+5) begin
        $error("Error: AXI lite address width too narrow (instance %m)");
        $finish;
    end

    if (PIPELINE < 1) begin
        $error("Error: PIPELINE must be at least 1 (instance %m)");
        $finish;
    end
end

reg op_axil_write_pipe_hazard;
reg op_axil_read_pipe_hazard;
reg op_doorbell_pipe_hazard;
reg op_req_pipe_hazard;
reg op_complete_pipe_hazard;
reg op_internal_pipe_hazard;
reg stage_active;

reg [PIPELINE-1:0] op_axil_write_pipe_reg = {PIPELINE{1'b0}}, op_axil_write_pipe_next;
reg [PIPELINE-1:0] op_axil_read_pipe_reg = {PIPELINE{1'b0}}, op_axil_read_pipe_next;
reg [PIPELINE-1:0] op_doorbell_pipe_reg = {PIPELINE{1'b0}}, op_doorbell_pipe_next;
reg [PIPELINE-1:0] op_req_pipe_reg = {PIPELINE{1'b0}}, op_req_pipe_next;
reg [PIPELINE-1:0] op_complete_pipe_reg = {PIPELINE{1'b0}}, op_complete_pipe_next;
reg [PIPELINE-1:0] op_internal_pipe_reg = {PIPELINE{1'b0}}, op_internal_pipe_next;

reg [QUEUE_INDEX_WIDTH-1:0] queue_ram_addr_pipeline_reg[PIPELINE-1:0], queue_ram_addr_pipeline_next[PIPELINE-1:0];
reg [QUEUE_RAM_WIDTH-1:0] queue_ram_read_data_pipeline_reg[PIPELINE-1:0];
reg [AXIL_DATA_WIDTH-1:0] write_data_pipeline_reg[PIPELINE-1:0], write_data_pipeline_next[PIPELINE-1:0];
reg [AXIL_STRB_WIDTH-1:0] write_strobe_pipeline_reg[PIPELINE-1:0], write_strobe_pipeline_next[PIPELINE-1:0];
reg [REQ_TAG_WIDTH-1:0] req_tag_pipeline_reg[PIPELINE-1:0], req_tag_pipeline_next[PIPELINE-1:0];
reg [CL_OP_TABLE_SIZE-1:0] op_index_pipeline_reg[PIPELINE-1:0], op_index_pipeline_next[PIPELINE-1:0];

reg [QUEUE_INDEX_WIDTH-1:0] m_axis_tx_req_queue_reg = {QUEUE_INDEX_WIDTH{1'b0}}, m_axis_tx_req_queue_next;
reg [REQ_TAG_WIDTH-1:0] m_axis_tx_req_tag_reg = {REQ_TAG_WIDTH{1'b0}}, m_axis_tx_req_tag_next;
reg m_axis_tx_req_valid_reg = 1'b0, m_axis_tx_req_valid_next;

reg s_axil_awready_reg = 0, s_axil_awready_next;
reg s_axil_wready_reg = 0, s_axil_wready_next;
reg s_axil_bvalid_reg = 0, s_axil_bvalid_next;
reg s_axil_arready_reg = 0, s_axil_arready_next;
reg [AXIL_DATA_WIDTH-1:0] s_axil_rdata_reg = 0, s_axil_rdata_next;
reg s_axil_rvalid_reg = 0, s_axil_rvalid_next;

reg [QUEUE_RAM_WIDTH-1:0] queue_ram[QUEUE_COUNT-1:0];
reg [QUEUE_INDEX_WIDTH-1:0] queue_ram_read_ptr;
reg [QUEUE_INDEX_WIDTH-1:0] queue_ram_write_ptr;
reg [QUEUE_RAM_WIDTH-1:0] queue_ram_write_data;
reg queue_ram_wr_en;
reg [QUEUE_RAM_BE_WIDTH-1:0] queue_ram_be;

wire queue_ram_read_data_enabled = queue_ram_read_data_pipeline_reg[PIPELINE-1][0];
wire queue_ram_read_data_active = queue_ram_read_data_pipeline_reg[PIPELINE-1][1];
wire queue_ram_read_data_scheduled = queue_ram_read_data_pipeline_reg[PIPELINE-1][2];
wire [CL_OP_TABLE_SIZE-1:0] queue_ram_read_data_op_tail_index = queue_ram_read_data_pipeline_reg[PIPELINE-1][15:8];

reg [OP_TABLE_SIZE-1:0] op_table_active = 0;
reg [OP_TABLE_SIZE-1:0] op_table_complete = 0;
reg [QUEUE_INDEX_WIDTH-1:0] op_table_queue[OP_TABLE_SIZE-1:0];
reg op_table_doorbell[OP_TABLE_SIZE-1:0];
reg op_table_tx_status[OP_TABLE_SIZE-1:0];
reg op_table_is_head[OP_TABLE_SIZE-1:0];
reg [CL_OP_TABLE_SIZE-1:0] op_table_next_index[OP_TABLE_SIZE-1:0];
reg [CL_OP_TABLE_SIZE-1:0] op_table_prev_index[OP_TABLE_SIZE-1:0];
wire [CL_OP_TABLE_SIZE-1:0] op_table_start_ptr;
wire op_table_start_ptr_valid;
reg [QUEUE_INDEX_WIDTH-1:0] op_table_start_queue;
reg op_table_start_en;
reg [CL_OP_TABLE_SIZE-1:0] op_table_doorbell_ptr;
reg op_table_doorbell_en;
reg [CL_OP_TABLE_SIZE-1:0] op_table_complete_ptr;
reg op_table_complete_tx_status;
reg op_table_complete_en;
wire [CL_OP_TABLE_SIZE-1:0] op_table_finish_ptr;
wire op_table_finish_ptr_valid;
reg op_table_finish_en;
reg [CL_OP_TABLE_SIZE-1:0] op_table_release_ptr;
reg op_table_release_en;
reg [CL_OP_TABLE_SIZE-1:0] op_table_update_next_ptr;
reg [CL_OP_TABLE_SIZE-1:0] op_table_update_next_index;
reg op_table_update_next_en;
reg [CL_OP_TABLE_SIZE-1:0] op_table_update_prev_ptr;
reg [CL_OP_TABLE_SIZE-1:0] op_table_update_prev_index;
reg op_table_update_prev_is_head;
reg op_table_update_prev_en;

reg init_reg = 1'b0, init_next;
reg [QUEUE_INDEX_WIDTH-1:0] init_index_reg = 0, init_index_next;

reg [QUEUE_INDEX_WIDTH:0] active_queue_count_reg = 0, active_queue_count_next;

assign m_axis_tx_req_queue = m_axis_tx_req_queue_reg;
assign m_axis_tx_req_tag = m_axis_tx_req_tag_reg;
assign m_axis_tx_req_valid = m_axis_tx_req_valid_reg;

assign s_axil_awready = s_axil_awready_reg;
assign s_axil_wready = s_axil_wready_reg;
assign s_axil_bresp = 2'b00;
assign s_axil_bvalid = s_axil_bvalid_reg;
assign s_axil_arready = s_axil_arready_reg;
assign s_axil_rdata = s_axil_rdata_reg;
assign s_axil_rresp = 2'b00;
assign s_axil_rvalid = s_axil_rvalid_reg;

assign active = active_queue_count_reg != 0;

wire [QUEUE_INDEX_WIDTH-1:0] s_axil_awaddr_queue = s_axil_awaddr >> 2;
wire [QUEUE_INDEX_WIDTH-1:0] s_axil_araddr_queue = s_axil_araddr >> 2;

wire queue_tail_active = op_table_active[queue_ram_read_data_op_tail_index] && op_table_queue[queue_ram_read_data_op_tail_index] == queue_ram_addr_pipeline_reg[PIPELINE-1];

wire [QUEUE_INDEX_WIDTH-1:0] axis_doorbell_fifo_queue;
wire axis_doorbell_fifo_valid;
reg axis_doorbell_fifo_ready;

axis_fifo #(
    .DEPTH(256),
    .DATA_WIDTH(QUEUE_INDEX_WIDTH),
    .KEEP_ENABLE(0),
    .KEEP_WIDTH(1),
    .LAST_ENABLE(0),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(0),
    .FRAME_FIFO(0)
)
doorbell_fifo (
    .clk(clk),
    .rst(rst),

    // AXI input
    .s_axis_tdata(s_axis_doorbell_queue),
    .s_axis_tkeep(0),
    .s_axis_tvalid(s_axis_doorbell_valid),
    .s_axis_tready(),
    .s_axis_tlast(0),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(0),

    // AXI output
    .m_axis_tdata(axis_doorbell_fifo_queue),
    .m_axis_tkeep(),
    .m_axis_tvalid(axis_doorbell_fifo_valid),
    .m_axis_tready(axis_doorbell_fifo_ready),
    .m_axis_tlast(),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(),

    // Status
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);

reg [QUEUE_INDEX_WIDTH-1:0] axis_scheduler_fifo_in_queue;
reg axis_scheduler_fifo_in_valid;
wire axis_scheduler_fifo_in_ready;

wire [QUEUE_INDEX_WIDTH-1:0] axis_scheduler_fifo_out_queue;
wire axis_scheduler_fifo_out_valid;
reg axis_scheduler_fifo_out_ready;

axis_fifo #(
    .DEPTH(2**QUEUE_INDEX_WIDTH),
    .DATA_WIDTH(QUEUE_INDEX_WIDTH),
    .KEEP_ENABLE(0),
    .KEEP_WIDTH(1),
    .LAST_ENABLE(0),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(0),
    .FRAME_FIFO(0)
)
rr_fifo (
    .clk(clk),
    .rst(rst),

    // AXI input
    .s_axis_tdata(axis_scheduler_fifo_in_queue),
    .s_axis_tkeep(0),
    .s_axis_tvalid(axis_scheduler_fifo_in_valid),
    .s_axis_tready(axis_scheduler_fifo_in_ready),
    .s_axis_tlast(0),
    .s_axis_tid(0),
    .s_axis_tdest(0),
    .s_axis_tuser(0),

    // AXI output
    .m_axis_tdata(axis_scheduler_fifo_out_queue),
    .m_axis_tkeep(),
    .m_axis_tvalid(axis_scheduler_fifo_out_valid),
    .m_axis_tready(axis_scheduler_fifo_out_ready),
    .m_axis_tlast(),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser(),

    // Status
    .status_overflow(),
    .status_bad_frame(),
    .status_good_frame()
);

priority_encoder #(
    .WIDTH(OP_TABLE_SIZE),
    .LSB_PRIORITY("HIGH")
)
op_table_start_enc_inst (
    .input_unencoded(~op_table_active),
    .output_valid(op_table_start_ptr_valid),
    .output_encoded(op_table_start_ptr),
    .output_unencoded()
);

priority_encoder #(
    .WIDTH(OP_TABLE_SIZE),
    .LSB_PRIORITY("HIGH")
)
op_table_finish_enc_inst (
    .input_unencoded(op_table_active & op_table_complete),
    .output_valid(op_table_finish_ptr_valid),
    .output_encoded(op_table_finish_ptr),
    .output_unencoded()
);

integer i;

initial begin
    for (i = 0; i < QUEUE_COUNT; i = i + 1) begin
        queue_ram[i] = 0;
    end

    for (i = 0; i < PIPELINE; i = i + 1) begin
        queue_ram_addr_pipeline_reg[i] = 0;
        write_data_pipeline_reg[i] = 0;
        write_strobe_pipeline_reg[i] = 0;
        req_tag_pipeline_reg[i] = 0;
    end

    for (i = 0; i < OP_TABLE_SIZE; i = i + 1) begin
        op_table_queue[i] = 0;
        op_table_next_index[i] = 0;
        op_table_prev_index[i] = 0;
        op_table_doorbell[i] = 0;
        op_table_tx_status[i] = 0;
        op_table_is_head[i] = 0;
    end
end

integer j;

always @* begin
    op_axil_write_pipe_next = {op_axil_write_pipe_reg, 1'b0};
    op_axil_read_pipe_next = {op_axil_read_pipe_reg, 1'b0};
    op_doorbell_pipe_next = {op_doorbell_pipe_reg, 1'b0};
    op_req_pipe_next = {op_req_pipe_reg, 1'b0};
    op_complete_pipe_next = {op_complete_pipe_reg, 1'b0};
    op_internal_pipe_next = {op_internal_pipe_reg, 1'b0};

    queue_ram_addr_pipeline_next[0] = 0;
    write_data_pipeline_next[0] = 0;
    write_strobe_pipeline_next[0] = 0;
    req_tag_pipeline_next[0] = 0;
    op_index_pipeline_next[0] = 0;
    for (j = 1; j < PIPELINE; j = j + 1) begin
        queue_ram_addr_pipeline_next[j] = queue_ram_addr_pipeline_reg[j-1];
        write_data_pipeline_next[j] = write_data_pipeline_reg[j-1];
        write_strobe_pipeline_next[j] = write_strobe_pipeline_reg[j-1];
        req_tag_pipeline_next[j] = req_tag_pipeline_reg[j-1];
        op_index_pipeline_next[j] = op_index_pipeline_reg[j-1];
    end

    m_axis_tx_req_queue_next = m_axis_tx_req_queue_reg;
    m_axis_tx_req_tag_next = m_axis_tx_req_tag_reg;
    m_axis_tx_req_valid_next = m_axis_tx_req_valid_reg && !m_axis_tx_req_ready;

    s_axil_awready_next = 1'b0;
    s_axil_wready_next = 1'b0;
    s_axil_bvalid_next = s_axil_bvalid_reg && !s_axil_bready;

    s_axil_arready_next = 1'b0;
    s_axil_rdata_next = s_axil_rdata_reg;
    s_axil_rvalid_next = s_axil_rvalid_reg && !s_axil_rready;

    queue_ram_read_ptr = 0;
    queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
    queue_ram_write_data = queue_ram_read_data_pipeline_reg[PIPELINE-1];
    queue_ram_wr_en = 0;
    queue_ram_be = 0;

    op_table_start_queue = queue_ram_addr_pipeline_reg[PIPELINE-1];
    op_table_start_en = 1'b0;
    op_table_doorbell_ptr = queue_ram_read_data_op_tail_index;
    op_table_doorbell_en = 1'b0;
    op_table_complete_ptr = s_axis_tx_req_status_tag;
    op_table_complete_tx_status = s_axis_tx_req_status_len != 0;
    op_table_complete_en = 1'b0;
    op_table_finish_en = 1'b0;
    op_table_release_ptr = op_index_pipeline_reg[PIPELINE-1];
    op_table_release_en = 1'b0;
    op_table_update_next_ptr = queue_ram_read_data_op_tail_index;
    op_table_update_next_index = op_index_pipeline_reg[PIPELINE-1];
    op_table_update_next_en = 1'b0;
    op_table_update_prev_ptr = op_index_pipeline_reg[PIPELINE-1];
    op_table_update_prev_index = queue_ram_read_data_op_tail_index;
    op_table_update_prev_is_head = !(queue_tail_active && op_index_pipeline_reg[PIPELINE-1] != queue_ram_read_data_op_tail_index);
    op_table_update_prev_en = 1'b0;

    init_next = init_reg;
    init_index_next = init_index_reg;

    active_queue_count_next = active_queue_count_reg;

    axis_doorbell_fifo_ready = 1'b0;

    axis_scheduler_fifo_in_queue = queue_ram_addr_pipeline_reg[PIPELINE-1];
    axis_scheduler_fifo_in_valid = 1'b0;

    axis_scheduler_fifo_out_ready = 1'b0;

    op_axil_write_pipe_hazard = 1'b0;
    op_axil_read_pipe_hazard = 1'b0;
    op_doorbell_pipe_hazard = 1'b0;
    op_req_pipe_hazard = 1'b0;
    op_complete_pipe_hazard = 1'b0;
    op_internal_pipe_hazard = 1'b0;
    stage_active = 1'b0;

    for (j = 0; j < PIPELINE; j = j + 1) begin
        stage_active = op_axil_write_pipe_reg[j] || op_axil_read_pipe_reg[j] || op_doorbell_pipe_reg[j] || op_req_pipe_reg[j] || op_complete_pipe_reg[j];
        op_axil_write_pipe_hazard = op_axil_write_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == s_axil_awaddr_queue);
        op_axil_read_pipe_hazard = op_axil_read_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == s_axil_araddr_queue);
        op_doorbell_pipe_hazard = op_doorbell_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == axis_doorbell_fifo_queue);
        op_req_pipe_hazard = op_req_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == axis_scheduler_fifo_out_queue);
        op_complete_pipe_hazard = op_complete_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == op_table_queue[op_table_finish_ptr]);
        op_internal_pipe_hazard = op_internal_pipe_hazard || (stage_active && queue_ram_addr_pipeline_reg[j] == init_index_reg);
    end

    // pipeline stage 0 - receive request
    if (!init_reg && !op_internal_pipe_hazard) begin
        // init queue states
        op_internal_pipe_next[0] = 1'b1;

        init_index_next = init_index_reg + 1;

        queue_ram_read_ptr = init_index_reg;
        queue_ram_addr_pipeline_next[0] = init_index_reg;

        if (init_index_reg == {QUEUE_INDEX_WIDTH{1'b1}}) begin
            init_next = 1'b1;
        end
    end else if (s_axil_awvalid && s_axil_wvalid && (!s_axil_bvalid || s_axil_bready) && !op_axil_write_pipe_reg[0] && !op_axil_write_pipe_hazard) begin
        // AXIL write
        op_axil_write_pipe_next[0] = 1'b1;

        s_axil_awready_next = 1'b1;
        s_axil_wready_next = 1'b1;

        write_data_pipeline_next[0] = s_axil_wdata;
        write_strobe_pipeline_next[0] = s_axil_wstrb;

        queue_ram_read_ptr = s_axil_awaddr_queue;
        queue_ram_addr_pipeline_next[0] = s_axil_awaddr_queue;
    end else if (s_axil_arvalid && (!s_axil_rvalid || s_axil_rready) && !op_axil_read_pipe_reg[0] && !op_axil_read_pipe_hazard) begin
        // AXIL read
        op_axil_read_pipe_next[0] = 1'b1;

        s_axil_arready_next = 1'b1;

        queue_ram_read_ptr = s_axil_araddr_queue;
        queue_ram_addr_pipeline_next[0] = s_axil_araddr_queue;
    end else if (axis_doorbell_fifo_valid && !op_doorbell_pipe_hazard) begin
        // handle doorbell
        op_doorbell_pipe_next[0] = 1'b1;

        axis_doorbell_fifo_ready = 1'b1;

        queue_ram_read_ptr = axis_doorbell_fifo_queue;
        queue_ram_addr_pipeline_next[0] = axis_doorbell_fifo_queue;
    end else if (op_table_finish_ptr_valid && !op_complete_pipe_reg[0] && !op_complete_pipe_hazard) begin
        // transmit complete
        op_complete_pipe_next[0] = 1'b1;

        op_table_finish_en = 1'b1;

        write_data_pipeline_next[0][0] = op_table_tx_status[op_table_finish_ptr] || op_table_doorbell[op_table_finish_ptr];
        op_index_pipeline_next[0] = op_table_finish_ptr;

        queue_ram_read_ptr = op_table_queue[op_table_finish_ptr];
        queue_ram_addr_pipeline_next[0] = op_table_queue[op_table_finish_ptr];
    end else if (enable && op_table_start_ptr_valid && axis_scheduler_fifo_out_valid && (!m_axis_tx_req_valid || m_axis_tx_req_ready) && !op_req_pipe_reg[0] && !op_req_pipe_hazard) begin
        // transmit request
        op_req_pipe_next[0] = 1'b1;

        op_table_start_en = 1'b1;
        op_table_start_queue = axis_scheduler_fifo_out_queue;

        op_index_pipeline_next[0] = op_table_start_ptr;

        axis_scheduler_fifo_out_ready = 1'b1;

        queue_ram_read_ptr = axis_scheduler_fifo_out_queue;
        queue_ram_addr_pipeline_next[0] = axis_scheduler_fifo_out_queue;
    end

    // read complete, perform operation
    if (op_internal_pipe_reg[PIPELINE-1]) begin
        // internal operation

        // init queue state
        queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
        queue_ram_write_data[0] = 1'b0; // queue enabled
        queue_ram_write_data[1] = 1'b0; // queue active
        queue_ram_write_data[2] = 1'b0; // queue scheduled
        queue_ram_be[0] = 1'b1;
        queue_ram_wr_en = 1'b1;
    end else if (op_doorbell_pipe_reg[PIPELINE-1]) begin
        // handle doorbell

        // mark queue active
        queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
        queue_ram_write_data[1] = 1'b1; // queue active
        queue_ram_be[0] = 1'b1;
        queue_ram_wr_en = 1'b1;

        // schedule queue if necessary
        if (queue_ram_read_data_enabled && !queue_ram_read_data_scheduled) begin
            queue_ram_write_data[2] = 1'b1; // queue scheduled

            axis_scheduler_fifo_in_queue = queue_ram_addr_pipeline_reg[PIPELINE-1];
            axis_scheduler_fifo_in_valid = 1'b1;

            active_queue_count_next = active_queue_count_reg + 1;
        end

        if (queue_tail_active) begin
            // record doorbell in table so we don't lose it
            op_table_doorbell_ptr = queue_ram_read_data_op_tail_index;
            op_table_doorbell_en = 1'b1;
        end
    end else if (op_req_pipe_reg[PIPELINE-1]) begin
        // transmit request
        m_axis_tx_req_queue_next = queue_ram_addr_pipeline_reg[PIPELINE-1];
        m_axis_tx_req_tag_next = op_index_pipeline_reg[PIPELINE-1];

        axis_scheduler_fifo_in_queue = queue_ram_addr_pipeline_reg[PIPELINE-1];

        // update state
        queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
        queue_ram_write_data[15:8] = op_index_pipeline_reg[PIPELINE-1]; // tail index
        queue_ram_be[0] = 1'b1;
        queue_ram_wr_en = 1'b1;

        op_table_update_prev_ptr = op_index_pipeline_reg[PIPELINE-1];
        op_table_update_prev_index = queue_ram_read_data_op_tail_index;
        op_table_update_prev_is_head = !(queue_tail_active && op_index_pipeline_reg[PIPELINE-1] != queue_ram_read_data_op_tail_index);

        op_table_update_next_ptr = queue_ram_read_data_op_tail_index;
        op_table_update_next_index = op_index_pipeline_reg[PIPELINE-1];

        if (queue_ram_read_data_enabled && queue_ram_read_data_active && queue_ram_read_data_scheduled) begin
            // queue enabled, active, and scheduled

            // issue transmit request
            m_axis_tx_req_valid_next = 1'b1;

            // reschedule
            axis_scheduler_fifo_in_valid = 1'b1;

            // update state
            queue_ram_write_data[2] = 1'b1; // queue scheduled
            queue_ram_be[1] = 1'b1; // tail index

            op_table_update_prev_en = 1'b1;
            op_table_update_next_en = queue_tail_active && op_index_pipeline_reg[PIPELINE-1] != queue_ram_read_data_op_tail_index;
        end else begin
            // queue not enabled, not active, or not scheduled
            // deschedule queue

            op_table_release_ptr = op_index_pipeline_reg[PIPELINE-1];
            op_table_release_en = 1'b1;

            // update state
            queue_ram_write_data[2] = 1'b0; // queue scheduled

            if (queue_ram_read_data_scheduled) begin
                active_queue_count_next = active_queue_count_reg - 1;
            end
        end
    end else if (op_complete_pipe_reg[PIPELINE-1]) begin
        // tx complete

        // update state
        queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
        queue_ram_be[0] = 1'b1;
        queue_ram_wr_en = 1'b1;

        op_table_update_prev_ptr = op_table_next_index[op_index_pipeline_reg[PIPELINE-1]];
        op_table_update_prev_index = op_table_prev_index[op_index_pipeline_reg[PIPELINE-1]];
        op_table_update_prev_is_head = op_table_is_head[op_index_pipeline_reg[PIPELINE-1]];
        op_table_update_prev_en = op_index_pipeline_reg[PIPELINE-1] != queue_ram_read_data_op_tail_index; // our next pointer only valid if we're not the tail

        op_table_update_next_ptr = op_table_prev_index[op_index_pipeline_reg[PIPELINE-1]];
        op_table_update_next_index = op_table_next_index[op_index_pipeline_reg[PIPELINE-1]];
        op_table_update_next_en = !op_table_is_head[op_index_pipeline_reg[PIPELINE-1]]; // our prev index only valid if we're not the head element

        op_table_doorbell_ptr = op_table_prev_index[op_index_pipeline_reg[PIPELINE-1]];
        op_table_doorbell_en = !op_table_is_head[op_index_pipeline_reg[PIPELINE-1]] && op_table_doorbell[op_index_pipeline_reg[PIPELINE-1]];;

        op_table_release_ptr = op_index_pipeline_reg[PIPELINE-1];
        op_table_release_en = 1'b1;

        if (write_data_pipeline_reg[PIPELINE-1][0]) begin
            queue_ram_write_data[1] = 1'b1; // queue active
        end else begin
            queue_ram_write_data[1] = 1'b0; // queue active
        end
    end else if (op_axil_write_pipe_reg[PIPELINE-1]) begin
        // AXIL write
        s_axil_bvalid_next = 1'b1;

        queue_ram_write_ptr = queue_ram_addr_pipeline_reg[PIPELINE-1];
        queue_ram_wr_en = 1'b1;

        queue_ram_write_data[0] = write_data_pipeline_reg[PIPELINE-1][0]; // queue enabled
        queue_ram_be[0] = 1'b1;

        // schedule if disabled
        if (write_data_pipeline_reg[PIPELINE-1][0] && queue_ram_read_data_active && !queue_ram_read_data_scheduled) begin
            axis_scheduler_fifo_in_queue = queue_ram_addr_pipeline_reg[PIPELINE-1];
            axis_scheduler_fifo_in_valid = 1'b1;

            active_queue_count_next = active_queue_count_reg + 1;
        end
    end else if (op_axil_read_pipe_reg[PIPELINE-1]) begin
        // AXIL read
        s_axil_rvalid_next = 1'b1;
        s_axil_rdata_next = 0;

        s_axil_rdata_next[0] = queue_ram_read_data_enabled;
        s_axil_rdata_next[16] = queue_ram_read_data_active;
        s_axil_rdata_next[24] = queue_ram_read_data_scheduled;
    end

    // finish transmit operation
    if (s_axis_tx_req_status_valid) begin
        op_table_complete_ptr = s_axis_tx_req_status_tag;
        op_table_complete_tx_status = s_axis_tx_req_status_len != 0;
        op_table_complete_en = 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        op_axil_write_pipe_reg <= {PIPELINE{1'b0}};
        op_axil_read_pipe_reg <= {PIPELINE{1'b0}};
        op_doorbell_pipe_reg <= {PIPELINE{1'b0}};
        op_req_pipe_reg <= {PIPELINE{1'b0}};
        op_complete_pipe_reg <= {PIPELINE{1'b0}};
        op_internal_pipe_reg <= {PIPELINE{1'b0}};

        m_axis_tx_req_valid_reg <= 1'b0;

        s_axil_awready_reg <= 1'b0;
        s_axil_wready_reg <= 1'b0;
        s_axil_bvalid_reg <= 1'b0;
        s_axil_arready_reg <= 1'b0;
        s_axil_rvalid_reg <= 1'b0;

        init_reg <= 1'b0;
        init_index_reg <= 0;

        active_queue_count_reg <= 0;

        op_table_active <= 0;
    end else begin
        op_axil_write_pipe_reg <= op_axil_write_pipe_next;
        op_axil_read_pipe_reg <= op_axil_read_pipe_next;
        op_doorbell_pipe_reg <= op_doorbell_pipe_next;
        op_req_pipe_reg <= op_req_pipe_next;
        op_complete_pipe_reg <= op_complete_pipe_next;
        op_internal_pipe_reg <= op_internal_pipe_next;

        m_axis_tx_req_valid_reg <= m_axis_tx_req_valid_next;

        s_axil_awready_reg <= s_axil_awready_next;
        s_axil_wready_reg <= s_axil_wready_next;
        s_axil_bvalid_reg <= s_axil_bvalid_next;
        s_axil_arready_reg <= s_axil_arready_next;
        s_axil_rvalid_reg <= s_axil_rvalid_next;

        init_reg <= init_next;
        init_index_reg <= init_index_next;

        active_queue_count_reg <= active_queue_count_next;

        if (op_table_start_en) begin
            op_table_active[op_table_start_ptr] <= 1'b1;
        end
        if (op_table_release_en) begin
            op_table_active[op_table_release_ptr] <= 1'b0;
        end
    end

    for (i = 0; i < PIPELINE; i = i + 1) begin
        queue_ram_addr_pipeline_reg[i] <= queue_ram_addr_pipeline_next[i];
        write_data_pipeline_reg[i] <= write_data_pipeline_next[i];
        write_strobe_pipeline_reg[i] <= write_strobe_pipeline_next[i];
        req_tag_pipeline_reg[i] <= req_tag_pipeline_next[i];
        op_index_pipeline_reg[i] <= op_index_pipeline_next[i];
    end

    m_axis_tx_req_queue_reg <= m_axis_tx_req_queue_next;
    m_axis_tx_req_tag_reg <= m_axis_tx_req_tag_next;

    s_axil_rdata_reg <= s_axil_rdata_next;

    if (queue_ram_wr_en) begin
        for (i = 0; i < QUEUE_RAM_BE_WIDTH; i = i + 1) begin
            if (queue_ram_be[i]) begin
                queue_ram[queue_ram_write_ptr][i*8 +: 8] <= queue_ram_write_data[i*8 +: 8];
            end
        end
    end
    queue_ram_read_data_pipeline_reg[0] <= queue_ram[queue_ram_read_ptr];
    for (i = 1; i < PIPELINE; i = i + 1) begin
        queue_ram_read_data_pipeline_reg[i] <= queue_ram_read_data_pipeline_reg[i-1];
    end

    if (op_table_start_en) begin
        op_table_complete[op_table_start_ptr] <= 1'b0;
        op_table_queue[op_table_start_ptr] <= op_table_start_queue;
        op_table_doorbell[op_table_start_ptr] <= 1'b0;
    end
    if (op_table_doorbell_en) begin
        op_table_doorbell[op_table_doorbell_ptr] <= 1'b1;
    end
    if (op_table_complete_en) begin
        op_table_complete[op_table_complete_ptr] <= 1'b1;
        op_table_tx_status[op_table_complete_ptr] <= op_table_complete_tx_status;
    end
    if (op_table_finish_en) begin
        op_table_complete[op_table_finish_ptr] <= 1'b0;
    end
    if (op_table_update_next_en) begin
        op_table_next_index[op_table_update_next_ptr] <= op_table_update_next_index;
    end
    if (op_table_update_prev_en) begin
        op_table_prev_index[op_table_update_prev_ptr] <= op_table_update_prev_index;
        op_table_is_head[op_table_update_prev_ptr] <= op_table_update_prev_is_head;
    end
end

endmodule