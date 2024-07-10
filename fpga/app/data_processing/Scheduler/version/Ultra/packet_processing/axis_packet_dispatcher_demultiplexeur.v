module axis_packet_dispatcher_demultiplexeur #(
    // Ethernet interface configuration
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,
    
    // State
    parameter STATE_WIDTH           = 3,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5
)(
    input wire  [STATE_WIDTH-1:0] state,

    input wire  [AXIS_DATA_WIDTH-1:0] s_axis_demultiplexeur_tdata,

    output wire [AXIS_DATA_WIDTH-1:0]  m_axis_demultiplexeur_to_multiplexeur_tdata,

    output wire [AXIS_DATA_WIDTH-1:0]  m_axis_demultiplexeur_to_parser_tdata
);
    assign m_axis_demultiplexeur_to_multiplexeur_tdata   = state == SEND_REMAIN ? s_axis_demultiplexeur_tdata : 0;

    assign m_axis_demultiplexeur_to_parser_tdata         = state == PARSE_DATA ? s_axis_demultiplexeur_tdata : 0;

endmodule
