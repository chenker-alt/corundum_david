module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/wrapper_sim_only.fst");
    $dumpvars(0, wrapper_sim_only);
end
endmodule
