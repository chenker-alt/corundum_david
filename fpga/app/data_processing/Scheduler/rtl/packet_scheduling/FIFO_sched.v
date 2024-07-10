module FIFO_sched #(
    parameter IF_COUNT_DOWN_RX = 3
   
)
(
    input clk,rst,

    input wire [IF_COUNT_DOWN_RX-1:0] s_axis_tvalid,
    input wire m_axis_mult_tlast,

    output reg [1:0] sel,
    output reg en=1
);

    reg [1:0] sel_next;
   
   // reg [1:0] rr_counter,rr_counter_next;
    //reg [31:0] packet_size [0:IF_COUNT_DOWN_RX-1];




    always @(posedge clk) begin
	if(rst) begin
		//rr_counter <= 0;
		sel <= 0;
	end else begin
         //   rr_counter <= rr_counter_next;
            sel <= sel_next; 
    end
end

always @(*) begin
    sel_next = sel;
  //  rr_counter_next = m_axis_mult_tlast ? (rr_counter == 2) ? 0 : rr_counter+1 : rr_counter;
    case (sel)
        0: begin
            if (m_axis_mult_tlast || !s_axis_tvalid[0]) begin
            	if (s_axis_tvalid[1]) begin
                	sel_next = 1;
                end else if (s_axis_tvalid[2]) begin
                	sel_next = 2;
                end
            end
        end
        1: begin
            if (m_axis_mult_tlast  || !s_axis_tvalid[1]) begin
            	if (s_axis_tvalid[2]) begin
                	sel_next = 2;
                end else if (s_axis_tvalid[0]) begin
                	sel_next = 0;
                end
            end
        end
        2: begin
            if (m_axis_mult_tlast  || !s_axis_tvalid[2]) begin
            	if (s_axis_tvalid[0]) begin
                	sel_next = 0;
                end else if (s_axis_tvalid[1]) begin
                	sel_next = 1;
                end
            end
        end
        default: begin
            sel_next = 0;
        //    rr_counter_next = 0;
        end
    endcase
end


endmodule
