module axi_stream_crossbar #(
    parameter IF_COUNT_DOWN_RX = 3,
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 9
)(
    input wire clk,
    input wire rst,

    input wire [IF_COUNT_DOWN_RX*AXIS_DATA_WIDTH-1:0]   s_axis_crossbar_tdata,
    input wire [IF_COUNT_DOWN_RX*AXIS_KEEP_WIDTH-1:0]   s_axis_crossbar_tkeep,
    input wire [IF_COUNT_DOWN_RX-1:0]                   s_axis_crossbar_tvalid,
    output wire [IF_COUNT_DOWN_RX-1:0]                  s_axis_crossbar_tready,
    input wire [IF_COUNT_DOWN_RX-1:0]                   s_axis_crossbar_tlast,
    input wire [IF_COUNT_DOWN_RX*AXIS_DEST_WIDTH-1:0]   s_axis_crossbar_tdest,

    output reg [AXIS_DATA_WIDTH-1:0]            m_axis_crossbar_fifo0_tdata,
    output reg [AXIS_KEEP_WIDTH-1:0]            m_axis_crossbar_fifo0_tkeep,
    output reg                                  m_axis_crossbar_fifo0_tvalid,
    input wire                                   m_axis_crossbar_fifo0_tready,
    output reg                                  m_axis_crossbar_fifo0_tlast, 

    output reg [AXIS_DATA_WIDTH-1:0]            m_axis_crossbar_fifo1_tdata,  
    output reg [AXIS_KEEP_WIDTH-1:0]            m_axis_crossbar_fifo1_tkeep,  
    output reg                                  m_axis_crossbar_fifo1_tvalid, 
    input wire                                   m_axis_crossbar_fifo1_tready, 
    output reg                                  m_axis_crossbar_fifo1_tlast,  

    output reg [AXIS_DATA_WIDTH-1:0]            m_axis_crossbar_fifo2_tdata,
    output reg [AXIS_KEEP_WIDTH-1:0]            m_axis_crossbar_fifo2_tkeep,
    output reg                                  m_axis_crossbar_fifo2_tvalid,
    input wire                                   m_axis_crossbar_fifo2_tready,
    output reg                                  m_axis_crossbar_fifo2_tlast





);
reg [2:0]current_selected_fifo_0, current_selected_fifo_1, current_selected_fifo_2;
wire current_selected_fifo_0_tlast,current_selected_fifo_1_tlast,current_selected_fifo_2_tlast;
reg [2:0]next_selected_fifo_0,next_selected_fifo_1,next_selected_fifo_2;

wire [AXIS_DATA_WIDTH-1:0] s_axis_port0_tdata, s_axis_port1_tdata, s_axis_port2_tdata;
wire [AXIS_KEEP_WIDTH-1:0] s_axis_port0_tkeep, s_axis_port1_tkeep, s_axis_port2_tkeep;
wire                       s_axis_port0_tvalid,s_axis_port1_tvalid,s_axis_port2_tvalid;
reg                        s_axis_port0_tready,s_axis_port1_tready,s_axis_port2_tready;
wire                       s_axis_port0_tlast,s_axis_port1_tlast,s_axis_port2_tlast;
wire [AXIS_DEST_WIDTH-1:0] s_axis_port0_tdest,s_axis_port1_tdest,s_axis_port2_tdest;

assign s_axis_port0_tdata =s_axis_crossbar_tdata[AXIS_DATA_WIDTH-1:0];
assign s_axis_port0_tkeep =s_axis_crossbar_tkeep[AXIS_KEEP_WIDTH-1:0];
assign s_axis_port0_tvalid=s_axis_crossbar_tvalid[0];
assign s_axis_port0_tlast =s_axis_crossbar_tlast[0];
assign s_axis_port0_tdest =s_axis_crossbar_tdest[AXIS_DEST_WIDTH-1:0];

assign s_axis_port1_tdata =s_axis_crossbar_tdata[(AXIS_DATA_WIDTH*2)-1-:AXIS_DATA_WIDTH];
assign s_axis_port1_tkeep =s_axis_crossbar_tkeep[(AXIS_KEEP_WIDTH*2)-1-:AXIS_KEEP_WIDTH];
assign s_axis_port1_tvalid=s_axis_crossbar_tvalid[1];
assign s_axis_port1_tlast =s_axis_crossbar_tlast[1];
assign s_axis_port1_tdest =s_axis_crossbar_tdest[(AXIS_DEST_WIDTH*2)-1-:AXIS_DEST_WIDTH];

assign s_axis_port2_tdata =s_axis_crossbar_tdata[(AXIS_DATA_WIDTH*3)-1-:2*AXIS_DATA_WIDTH];
assign s_axis_port2_tkeep =s_axis_crossbar_tkeep[(AXIS_KEEP_WIDTH*3)-1-:2*AXIS_KEEP_WIDTH];
assign s_axis_port2_tvalid=s_axis_crossbar_tvalid[2];
assign s_axis_port2_tlast =s_axis_crossbar_tlast[2];
assign s_axis_port2_tdest =s_axis_crossbar_tdest[(AXIS_DEST_WIDTH*3)-1-:2*AXIS_DEST_WIDTH];

assign s_axis_crossbar_tready = {s_axis_port2_tready,s_axis_port1_tready,s_axis_port0_tready};

assign current_selected_fifo_0_tlast =  (current_selected_fifo_0 == 0) ? s_axis_port0_tdata :
                                        (current_selected_fifo_0 == 1) ? s_axis_port1_tdata :
                                        (current_selected_fifo_0 == 2) ? s_axis_port2_tdata :
                                        0 ;

assign current_selected_fifo_1_tlast =  (current_selected_fifo_1 == 0) ? s_axis_port0_tdata :
                                        (current_selected_fifo_1 == 1) ? s_axis_port1_tdata :
                                        (current_selected_fifo_1 == 2) ? s_axis_port2_tdata :
                                        0 ;

assign current_selected_fifo_2_tlast =  (current_selected_fifo_2 == 0) ? s_axis_port0_tdata :
                                        (current_selected_fifo_2 == 1) ? s_axis_port1_tdata :
                                        (current_selected_fifo_2 == 2) ? s_axis_port2_tdata :
                                        0 ;


// arbitration
always @(*) begin
    next_selected_fifo_0 = current_selected_fifo_0;
    next_selected_fifo_1 = current_selected_fifo_1;
    next_selected_fifo_2 = current_selected_fifo_2;

    // fifo 0
    if (s_axis_port0_tvalid && s_axis_port0_tdest == 0) begin
        next_selected_fifo_0 = 0; 
    end else if (s_axis_port1_tvalid && s_axis_port1_tdest == 0) begin
        next_selected_fifo_0 = 1; 
    end else if (s_axis_port2_tvalid && s_axis_port2_tdest == 0) begin
        next_selected_fifo_0 = 2; 
    end

    // fif0 1
    if (s_axis_port0_tvalid && s_axis_port0_tdest == 1) begin
        next_selected_fifo_1 = 0; 
    end else if (s_axis_port1_tvalid && s_axis_port1_tdest == 1) begin
        next_selected_fifo_1 = 1; 
    end else if (s_axis_port2_tvalid && s_axis_port2_tdest == 1) begin
        next_selected_fifo_1 = 2; 
    end

    // fifo 2
    if (s_axis_port0_tvalid && s_axis_port0_tdest == 2) begin
        next_selected_fifo_2 = 0; 
    end else if (s_axis_port1_tvalid && s_axis_port1_tdest == 2) begin
        next_selected_fifo_2 = 1; 
    end else if (s_axis_port2_tvalid && s_axis_port2_tdest == 2) begin
        next_selected_fifo_2 = 2; 
    end
end

always @(posedge clk) begin
    if (rst) begin
        current_selected_fifo_0 <= 0;
        current_selected_fifo_1 <= 0;
        current_selected_fifo_2 <= 0;

        m_axis_crossbar_fifo0_tvalid <= 0;
        m_axis_crossbar_fifo1_tvalid <= 0;
        m_axis_crossbar_fifo2_tvalid <= 0;

        s_axis_port0_tready <= 0;
        s_axis_port1_tready <= 0;
        s_axis_port2_tready <= 0;
    end else begin
        if(current_selected_fifo_0_tlast)begin
            current_selected_fifo_0<=next_selected_fifo_0;
        end

        if(current_selected_fifo_1_tlast)begin
            current_selected_fifo_1<=next_selected_fifo_1;
        end

        if(current_selected_fifo_2_tlast)begin
            current_selected_fifo_2<=next_selected_fifo_2;
        end

        case (s_axis_port0_tdest)
        0:begin
            if((current_selected_fifo_0==0) && m_axis_crossbar_fifo0_tready)begin
                m_axis_crossbar_fifo0_tdata=s_axis_port0_tdata;
                m_axis_crossbar_fifo0_tkeep=s_axis_port0_tkeep;
                m_axis_crossbar_fifo0_tvalid=s_axis_port0_tvalid;
                m_axis_crossbar_fifo0_tlast=s_axis_port0_tlast;
                s_axis_port0_tready=m_axis_crossbar_fifo0_tready;
            end
        end

        1:begin
            if((current_selected_fifo_1==0) && m_axis_crossbar_fifo1_tready)begin
                m_axis_crossbar_fifo1_tdata=s_axis_port0_tdata;
                m_axis_crossbar_fifo1_tkeep=s_axis_port0_tkeep;
                m_axis_crossbar_fifo1_tvalid=s_axis_port0_tvalid;
                m_axis_crossbar_fifo1_tlast=s_axis_port0_tlast;
                s_axis_port0_tready=m_axis_crossbar_fifo1_tready;
            end
        end

        2:begin
            if((current_selected_fifo_2==0) && m_axis_crossbar_fifo2_tready)begin
                m_axis_crossbar_fifo2_tdata=s_axis_port0_tdata;
                m_axis_crossbar_fifo2_tkeep=s_axis_port0_tkeep;
                m_axis_crossbar_fifo2_tvalid=s_axis_port0_tvalid;
                m_axis_crossbar_fifo2_tlast=s_axis_port0_tlast;
                s_axis_port0_tready=m_axis_crossbar_fifo2_tready;
            end
        end
        endcase

            case (s_axis_port1_tdest)
        0:begin
            if((current_selected_fifo_0==1) && m_axis_crossbar_fifo0_tready)begin
                m_axis_crossbar_fifo0_tdata=s_axis_port1_tdata;
                m_axis_crossbar_fifo0_tkeep=s_axis_port1_tkeep;
                m_axis_crossbar_fifo0_tvalid=s_axis_port1_tvalid;
                m_axis_crossbar_fifo0_tlast=s_axis_port1_tlast;
                s_axis_port1_tready=m_axis_crossbar_fifo0_tready;
            end
        end

        1:begin
            if((current_selected_fifo_1==1) && m_axis_crossbar_fifo1_tready)begin
                m_axis_crossbar_fifo1_tdata=s_axis_port1_tdata;
                m_axis_crossbar_fifo1_tkeep=s_axis_port1_tkeep;
                m_axis_crossbar_fifo1_tvalid=m_axis_crossbar_fifo1_tvalid;
                m_axis_crossbar_fifo1_tlast=s_axis_port1_tlast;
                s_axis_port1_tready=m_axis_crossbar_fifo1_tready;
            end
        end

        2:begin
            if((current_selected_fifo_2==1) && m_axis_crossbar_fifo2_tready)begin
                m_axis_crossbar_fifo2_tdata=s_axis_port1_tdata;
                m_axis_crossbar_fifo2_tkeep=s_axis_port1_tkeep;
                m_axis_crossbar_fifo2_tvalid=s_axis_port1_tvalid;
                m_axis_crossbar_fifo2_tlast=s_axis_port1_tlast;
                s_axis_port1_tready=m_axis_crossbar_fifo2_tready;
            end
        end
        endcase

            case (s_axis_port2_tdest)
        0:begin
            if((current_selected_fifo_0==2) && m_axis_crossbar_fifo0_tready)begin
                m_axis_crossbar_fifo0_tdata=s_axis_port2_tdata;
                m_axis_crossbar_fifo0_tkeep=s_axis_port2_tkeep;
                m_axis_crossbar_fifo0_tvalid=s_axis_port2_tvalid;
                m_axis_crossbar_fifo0_tlast=s_axis_port2_tlast;
                s_axis_port2_tready=m_axis_crossbar_fifo0_tready;
            end
        end

        1:begin
            if((current_selected_fifo_1==2) && m_axis_crossbar_fifo1_tready)begin
                m_axis_crossbar_fifo1_tdata=s_axis_port2_tdata;
                m_axis_crossbar_fifo1_tkeep=s_axis_port2_tkeep;
                m_axis_crossbar_fifo1_tvalid=s_axis_port2_tvalid;
                m_axis_crossbar_fifo1_tlast=s_axis_port2_tlast;
                s_axis_port2_tready=m_axis_crossbar_fifo1_tready;
            end
        end

        2:begin
            if((current_selected_fifo_2==2) && m_axis_crossbar_fifo2_tready)begin
                m_axis_crossbar_fifo2_tdata=s_axis_port2_tdata;
                m_axis_crossbar_fifo2_tkeep=s_axis_port2_tkeep;
                m_axis_crossbar_fifo2_tvalid=s_axis_port2_tvalid;
                m_axis_crossbar_fifo2_tlast=s_axis_port2_tlast;
                s_axis_port2_tready=m_axis_crossbar_fifo2_tready;
            end
        end
        endcase
    end
end
endmodule