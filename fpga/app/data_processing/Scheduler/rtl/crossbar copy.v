module axi_stream_crossbar #(
    parameter AXIS_DATA_WIDTH = 64,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_DEST_WIDTH = 9
)(
    input wire clk,
    input wire rst,

    input wire [AXIS_DATA_WIDTH-1:0] s0_tdata, s1_tdata, s2_tdata,
    input wire s0_tvalid, s1_tvalid, s2_tvalid,
    output reg s0_tready, s1_tready, s2_tready,
    input wire s0_tlast, s1_tlast, s2_tlast,
    input wire [AXIS_DEST_WIDTH-1:0] s0_tdest, s1_tdest, s2_tdest,

    output reg [AXIS_DATA_WIDTH-1:0] m0_tdata, m1_tdata, m2_tdata,
    output reg m0_tvalid, m1_tvalid, m2_tvalid,
    input wire m0_tready, m1_tready, m2_tready,
    output reg m0_tlast, m1_tlast, m2_tlast
);
reg [2:0]current_selected_fifo_0, current_selected_fifo_1, current_selected_fifo_2;
wire current_selected_fifo_0_tlast,current_selected_fifo_1_tlast,current_selected_fifo_2_tlast;
reg [2:0]next_selected_fifo_0,next_selected_fifo_1,next_selected_fifo_2;

assign current_selected_fifo_0_tlast =  (current_selected_fifo_0 == 0) ? s0_tlast :
                                        (current_selected_fifo_0 == 1) ? s1_tlast :
                                        (current_selected_fifo_0 == 2) ? s2_tlast :
                                        0 ;

assign current_selected_fifo_1_tlast =  (current_selected_fifo_1 == 0) ? s0_tlast :
                                        (current_selected_fifo_1 == 1) ? s1_tlast :
                                        (current_selected_fifo_1 == 2) ? s2_tlast :
                                        0 ;

assign current_selected_fifo_2_tlast =  (current_selected_fifo_2 == 0) ? s0_tlast :
                                        (current_selected_fifo_2 == 1) ? s1_tlast :
                                        (current_selected_fifo_2 == 2) ? s2_tlast :
                                        0 ;


// arbitration
always @(*) begin
    next_selected_fifo_0 = current_selected_fifo_0;
    next_selected_fifo_1 = current_selected_fifo_1;
    next_selected_fifo_2 = current_selected_fifo_2;

    // fifo 0
    if (s0_tvalid && s0_tdest == 0) begin
        next_selected_fifo_0 = 0; 
    end else if (s1_tvalid && s1_tdest == 0) begin
        next_selected_fifo_0 = 1; 
    end else if (s2_tvalid && s2_tdest == 0) begin
        next_selected_fifo_0 = 2; 
    end

    // fif0 1
    if (s0_tvalid && s0_tdest == 1) begin
        next_selected_fifo_1 = 0; 
    end else if (s1_tvalid && s1_tdest == 1) begin
        next_selected_fifo_1 = 1; 
    end else if (s2_tvalid && s2_tdest == 1) begin
        next_selected_fifo_1 = 2; 
    end

    // fifo 2
    if (s0_tvalid && s0_tdest == 2) begin
        next_selected_fifo_2 = 0; 
    end else if (s1_tvalid && s1_tdest == 2) begin
        next_selected_fifo_2 = 1; 
    end else if (s2_tvalid && s2_tdest == 2) begin
        next_selected_fifo_2 = 2; 
    end
end

always @(posedge clk) begin
    if (rst) begin
        current_selected_fifo_0 <= 0;
        current_selected_fifo_1 <= 0;
        current_selected_fifo_2 <= 0;

        m0_tvalid <= 0;
        m1_tvalid <= 0;
        m2_tvalid <= 0;

        m0_tlast <= 0;
        m1_tlast <= 0;
        m2_tlast <= 0;

        s0_tready <= 0;
        s1_tready <= 0;
        s2_tready <= 0;
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

        case (s0_tdest)
        0:begin
            if((current_selected_fifo_0==0) && m0_tready)begin
                m0_tdata=s0_tdata;
                m0_tvalid=s0_tvalid;
                s0_tready=m0_tready;
                m0_tlast=s0_tlast;
            end
        end

        1:begin
            if((current_selected_fifo_1==0) && m1_tready)begin
                m1_tdata=s0_tdata;
                m1_tvalid=s0_tvalid;
                s1_tready=m0_tready;
                m1_tlast=s0_tlast;
            end
        end

        2:begin
            if((current_selected_fifo_2==0) && m2_tready)begin
                m2_tdata=s0_tdata;
                m2_tvalid=s0_tvalid;
                s2_tready=m0_tready;
                m2_tlast=s0_tlast;
            end
        end
        endcase

            case (s1_tdest)
        0:begin
            if((current_selected_fifo_0==1) && m0_tready)begin
                m0_tdata=s1_tdata;
                m0_tvalid=s1_tvalid;
                s0_tready=m1_tready;
                m0_tlast=s1_tlast;
            end
        end

        1:begin
            if((current_selected_fifo_1==1) && m1_tready)begin
                m1_tdata=s1_tdata;
                m1_tvalid=m1_tvalid;
                s1_tready=m1_tready;
                m1_tlast=s1_tlast;
            end
        end

        2:begin
            if((current_selected_fifo_2==1) && m2_tready)begin
                m2_tdata=s1_tdata;
                m2_tvalid=s1_tvalid;
                s2_tready=m1_tready;
                m2_tlast=s1_tlast;
            end
        end
        endcase

            case (s2_tdest)
        0:begin
            if((current_selected_fifo_0==2) && m0_tready)begin
                m0_tdata=s2_tdata;
                m0_tvalid=s2_tvalid;
                s0_tready=m2_tready;
                m0_tlast=s2_tlast;
            end
        end

        1:begin
            if((current_selected_fifo_1==2) && m1_tready)begin
                m1_tdata=s2_tdata;
                m1_tvalid=s2_tvalid;
                s1_tready=m2_tready;
                m1_tlast=s2_tlast;
            end
        end

        2:begin
            if((current_selected_fifo_2==2) && m2_tready)begin
                m2_tdata=s2_tdata;
                m2_tvalid=s2_tvalid;
                s2_tready=m2_tready;
                m2_tlast=s2_tlast;
            end
        end
        endcase
    end
end
endmodule