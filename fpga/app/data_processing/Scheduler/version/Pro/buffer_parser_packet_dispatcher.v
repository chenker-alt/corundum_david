module buffer #(
    // Ethernet interface configuration
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 2,

    // Buffer configuration  
    parameter BUFFER_DATA_WIDTH = 192,
    parameter COUNTER_WIDTH = $clog2(BUFFER_DATA_WIDTH/AXIS_DATA_WIDTH+1), //2
    
    // Elements to parse
    parameter TCAM_KEY_WIDTH = 48,
    parameter PACKET_LENGTH_OFFSET = 14*8 + 2*8,
    parameter PACKET_LENGTH_WIDTH = 2*8,

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
    input wire clk,

    input wire [STATE_WIDTH-1:0] state,
    input wire [COUNTER_WIDTH-1:0] count,

    input wire [AXIS_DATA_WIDTH-1:0]    s_axis_parser_tdata,

    output wire [AXIS_DATA_WIDTH-1:0]    m_axis_parser_tdata,
    output wire [TCAM_KEY_WIDTH-1:0]     tcam_key,
    output reg [PACKET_LENGTH_WIDTH-1:0] packet_length

);
reg  [BUFFER_DATA_WIDTH-1:0] 	reg_meta_tdata;

assign tcam_key = reg_meta_tdata[BUFFER_DATA_WIDTH-1 -: TCAM_KEY_WIDTH];
assign packet_length = reg_meta_tdata[BUFFER_DATA_WIDTH-PACKET_LENGTH_OFFSET-1 -: PACKET_LENGTH_WIDTH];

assign m_axis_parser_tdata = reverse_bytes(reg_meta_tdata[BUFFER_DATA_WIDTH-count*AXIS_DATA_WIDTH-1-:AXIS_DATA_WIDTH]);


    function [AXIS_DATA_WIDTH-1:0] reverse_bytes(input [AXIS_DATA_WIDTH-1:0] data);
        parameter BYTE_WIDTH = 8;
        parameter NUM_BYTES = AXIS_DATA_WIDTH / BYTE_WIDTH;
        integer i;
        begin
            for (i = 0; i < NUM_BYTES; i = i + 1) begin
                reverse_bytes[i*BYTE_WIDTH +: BYTE_WIDTH] = data[(NUM_BYTES-1-i)*BYTE_WIDTH +: BYTE_WIDTH];
            end
        end
    endfunction

    always @(posedge clk) begin
        case(state)
            IDLE:begin
                reg_meta_tdata                  =0;

            end
            PARSE_DATA:begin
                reg_meta_tdata  [(BUFFER_DATA_WIDTH)-count*AXIS_DATA_WIDTH-1-:AXIS_DATA_WIDTH]=reverse_bytes(s_axis_parser_tdata);
            end
            default: begin
                reg_meta_tdata                  <= reg_meta_tdata;

            end
        endcase
    end
endmodule




