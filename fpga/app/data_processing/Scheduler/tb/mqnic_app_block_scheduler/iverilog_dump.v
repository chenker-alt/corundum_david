module iverilog_dump();
initial begin
    $dumpfile("wrapper_sim_only.fst");
    $dumpvars(0, wrapper_sim_only);
end
endmodule
