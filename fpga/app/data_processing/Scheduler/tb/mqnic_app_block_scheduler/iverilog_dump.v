module iverilog_dump();
initial begin
    $dumpfile("mqnic_app_block_scheduler.fst");
    $dumpvars(0, mqnic_app_block_scheduler);
end
endmodule
