module drr_scheduler #(
    parameter IF_COUNT_DOWN_RX = 3, 
    parameter QUANTUM= 1500,
    parameter PKT_LEN_WIDTH = 16,
)(
    input wire clk,rst,
    input wire [IF_COUNT_DOWN_RX-1:0] s_axis_tvalid,
    input wire m_axis_mult_tlast,
    input wire [PKT_LEN_WIDTH-1:0] current_packet_length,

    output reg [1:0] sel,
    output reg en
);
    reg [1:0] next_sel;
    reg [PKT_LEN_WIDTH-1:0] deficit_counter [0:IF_COUNT_DOWN_RX-1];
    reg [PKT_LEN_WIDTH-1:0] next_deficit_counter [0:IF_COUNT_DOWN_RX-1];
    
    integer i;
    
    always @(posedge clk) begin
    	if(rst) begin
    		sel <= 0;
    		for ( i = 0; i < IF_COUNT_DOWN_RX; i = i+1) begin
    			deficit_counter[i] <= 0;
    		end
    	end else begin
    		sel <= next_sel;
    		for ( i = 0; i < IF_COUNT_DOWN_RX; i = i+1) begin
    			deficit_counter[i] <= next_deficit_counter[i];
    		end
    	end
    end
    
    always @(*) begin
    	sel_next =sel;
    	en = 1'b0;
    	for ( i = 0; i < IF_COUNT_DOWN_RX; i = i+1) begin
    		next_deficit_counter[i] = deficit_counter[i];
    	end
    	case(sel)
    		0,1,2:begin
    			if(!s_axis_tvalid[sel]) begin
    				deficit_counter_next[sel] = 0;
    				next_sel = (sel + 1) % IF_COUNT_DOWN_RX;
    			end else if (m_axis_mult_tlast || !s_axis_tvalid[sel]) begin
    				deficit_counter_next[sel] = deficit_counter[sel] + QUANTUM;
    				if (current_packet_size <= deficit_counter_next[sel]) begin
                    			en = 1'b1;
                    			deficit_counter_next[sel] = deficit_counter_next[sel] - current_packet_length;
                    		end else begin
                    			next_sel = (sel + 1) % IF_COUNT_DOWN_RX;
                    		end
    			end
    		end
    		default:begin
    			next_sel =0;
    		end
    	endcase
    end

endmodule
