module init_rst_tcam #(
    // tcam
    parameter TCAM_ADDR_WIDTH = 4,
    parameter TCAM_KEY_WIDTH = 4,
    parameter TCAM_DATA_WIDTH = 4,
    parameter TCAM_MASK_DISABLE = 0,
    parameter TCAM_RAM_STYLE_DATA = "block",

    // State
    parameter STATE_WIDTH           = 3,

    parameter IDLE                  = 0,
    parameter PARSE_DATA            = 1,
    parameter CONTROL               = 2,
    parameter SEND_ANALYSED_DATA    = 3,
    parameter SEND_REMAIN           = 4,
    parameter DROP                  = 5,
    parameter TCAM_INIT             = 6
)
(
    input wire clk,
    input wire rst,

    input wire [STATE_WIDTH-1:0] state,

    output wire [TCAM_ADDR_WIDTH-1:0] init_set_addr,
    output wire [TCAM_DATA_WIDTH-1:0] init_set_data,
    output wire [TCAM_KEY_WIDTH-1:0] init_set_key,
    output wire [TCAM_KEY_WIDTH-1:0] init_set_xmask,
    output wire init_set_clr,
    output wire init_set_valid,

    output wire end_init_tcam
);

localparam N_LINE = 3;
localparam N_LINE_WIDTH = $clog2(N_LINE);
reg [N_LINE_WIDTH-1:0] count,next_count=0;

reg [TCAM_ADDR_WIDTH-1:0] reg_init_set_addr=0;
reg [TCAM_DATA_WIDTH-1:0] reg_init_set_data=0;
reg [TCAM_KEY_WIDTH-1:0] reg_init_set_key=0;
reg [TCAM_KEY_WIDTH-1:0] reg_init_set_xmask=0;
reg reg_init_set_clr=0;
reg reg_init_set_valid=0;

assign init_set_addr = reg_init_set_addr;
assign init_set_data = reg_init_set_data;
assign init_set_key = reg_init_set_key;
assign init_set_xmask = reg_init_set_xmask;
assign init_set_clr = reg_init_set_clr;
assign init_set_valid = reg_init_set_valid;

reg reg_end_init_tcam=0;
assign end_init_tcam = reg_end_init_tcam;

always @(posedge clk) begin
    if (rst == 1'b1) begin
        count <= 0;
        next_count <= 0;
    end else if (state == TCAM_INIT) begin
        count <= next_count;
        next_count <=count + 1;
    end else begin
        count <= 0;
        next_count <=0;
    end
end

always @(*)begin
    case (state)
        TCAM_INIT:begin
        reg_init_set_addr <=0;
        reg_init_set_data <=0;
        reg_init_set_key <=0;
        reg_init_set_xmask <=0;
        reg_init_set_clr <=0;
        reg_init_set_valid<=0;
        case(count)
            0:begin
                reg_end_init_tcam=1'b0;
                reg_init_set_addr <=1;
                reg_init_set_data <= 0;
                reg_init_set_key <= {48'h555555555503};
                reg_init_set_xmask <={48'h000000000000};
                reg_init_set_clr <=0;
                reg_init_set_valid <=1;
            end
            1:begin
                reg_end_init_tcam=1'b0;
                reg_init_set_addr <=2;
                reg_init_set_data <= 1;
                reg_init_set_key <={48'h555555555502};
                reg_init_set_xmask <={48'h000000000000};
                reg_init_set_clr <=0;
                reg_init_set_valid <=1;
            end
            2:begin
                reg_end_init_tcam=1'b0;
                reg_init_set_addr <=3;
                reg_init_set_data <= 2;
                reg_init_set_key <={48'h555555555501};
                reg_init_set_xmask <={48'h000000000000};
                reg_init_set_clr <=0;
                reg_init_set_valid <=1;
            end
            N_LINE:begin
                reg_end_init_tcam=1'b1;
                reg_init_set_addr <=0;
                reg_init_set_data <=0;
                reg_init_set_key <=0;
                reg_init_set_xmask <=0;
                reg_init_set_clr <=0;
                reg_init_set_valid <=0;
            end
        endcase
        end
        default: begin
                reg_end_init_tcam=1'b1;
                reg_init_set_addr <=0;
                reg_init_set_data <=0;
                reg_init_set_key <=0;
                reg_init_set_xmask <=0;
                reg_init_set_clr <=0;
                reg_init_set_valid <=0;
        end
    endcase
end

endmodule
