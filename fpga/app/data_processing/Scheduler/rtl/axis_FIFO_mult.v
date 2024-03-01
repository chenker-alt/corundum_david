module FIFO_mult #(

parameter AXIS_DATA_WIDTH = 64,
parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
parameter AXIS_DEST_WIDTH = 9
)
(
    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_priority_fifo0_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0]    s_axis_priority_fifo0_tkeep,
    input wire                          s_axis_priority_fifo0_tvalid,
    output wire                         s_axis_priority_fifo0_tready,
    input wire                          s_axis_priority_fifo0_tlast,

    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_priority_fifo1_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0]    s_axis_priority_fifo1_tkeep,
    input wire                          s_axis_priority_fifo1_tvalid,
    output wire                         s_axis_priority_fifo1_tready,
    input wire                          s_axis_priority_fifo1_tlast,

    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_priority_fifo2_tdata,
    input wire [AXIS_KEEP_WIDTH-1:0]    s_axis_priority_fifo2_tkeep,
    input wire                          s_axis_priority_fifo2_tvalid,
    output wire                         s_axis_priority_fifo2_tready,
    input wire                          s_axis_priority_fifo2_tlast,
    
    output wire [AXIS_DATA_WIDTH-1:0]   m_axis_priority_mult_fifo_tdata,
    output wire [AXIS_KEEP_WIDTH-1:0]   m_axis_priority_mult_fifo_tkeep,
    output wire                         m_axis_priority_mult_fifo_tvalid,
    input wire                          m_axis_priority_mult_fifo_tready,
    output wire                         m_axis_priority_mult_fifo_tlast
    );


    assign  m_axis_priority_mult_fifo_tdata  =      (s_axis_priority_fifo0_tvalid == 1 ) ? s_axis_priority_fifo0_tdata :
                                                    (s_axis_priority_fifo1_tvalid == 1 ) ? s_axis_priority_fifo1_tdata :
                                                    (s_axis_priority_fifo2_tvalid == 1 ) ? s_axis_priority_fifo2_tdata :
                                                    0;

    assign  m_axis_priority_mult_fifo_tkeep  =      (s_axis_priority_fifo0_tvalid == 1 ) ? s_axis_priority_fifo0_tkeep :
                                                    (s_axis_priority_fifo1_tvalid == 1 ) ? s_axis_priority_fifo1_tkeep :
                                                    (s_axis_priority_fifo2_tvalid == 1 ) ? s_axis_priority_fifo2_tkeep :
                                                    0;
    
    assign  m_axis_priority_mult_fifo_tvalid =      (s_axis_priority_fifo0_tvalid == 1 ) ? s_axis_priority_fifo0_tvalid :
                                                    (s_axis_priority_fifo1_tvalid == 1 ) ? s_axis_priority_fifo1_tvalid :
                                                    (s_axis_priority_fifo2_tvalid == 1 ) ? s_axis_priority_fifo2_tvalid :
                                                    0;


    assign  m_axis_priority_mult_fifo_tlast =       (s_axis_priority_fifo0_tvalid == 1 ) ? s_axis_priority_fifo0_tlast:
                                                    (s_axis_priority_fifo1_tvalid == 1 ) ? s_axis_priority_fifo1_tlast :
                                                    (s_axis_priority_fifo2_tvalid == 1 ) ? s_axis_priority_fifo2_tlast :
                                                    0;
                                
    assign s_axis_priority_fifo0_tready = (s_axis_priority_fifo0_tvalid == 1) ? m_axis_priority_mult_fifo_tready : 0;
    assign s_axis_priority_fifo1_tready = (s_axis_priority_fifo1_tvalid == 1 && s_axis_priority_fifo0_tvalid == 0) ? m_axis_priority_mult_fifo_tready : 0;
    assign s_axis_priority_fifo2_tready = (s_axis_priority_fifo2_tvalid == 1 && s_axis_priority_fifo0_tvalid == 0 && s_axis_priority_fifo1_tvalid == 0) ? m_axis_priority_mult_fifo_tready : 0;

endmodule