`timescale 1ns/1ps

module cpu_tb();

    logic clk;
    logic reset;

    cpu dut (.clk(clk), .reset(reset));


    //generate long clock cycle
    always begin
        #100 clk = ~clk;
    end

    initial begin
        clk = 0;
        reset = 1;
        
        @(posedge clk);
        @(posedge clk);

        //hold reset
        #10 reset = 0;

        //keep clk cycle for long time
        for(int i=0; i<10; i++) begin
            @(posedge clk);
        end

    end
endmodule
