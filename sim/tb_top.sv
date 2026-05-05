`timescale 1ns/1ps

module tb_top;
    reg ACLK;
    reg ARESETn;

    wire [31:0] AWADDR;
    wire        AWVALID;
    wire        AWREADY;
    wire [31:0] WDATA;
    wire [3:0]  WSTRB;
    wire        WVALID;
    wire        WREADY;
    wire [1:0]  BRESP;
    wire        BVALID;
    wire        BREADY;
    wire [31:0] ARADDR;
    wire        ARVALID;
    wire        ARREADY;
    wire [31:0] RDATA;
    wire [1:0]  RRESP;
    wire        RVALID;
    wire        RREADY;
    wire        irq_out;
    wire [31:0] assertion_errors;

    integer pass;
    integer total_pass;
    integer total_tests;
    reg [1023:0] testname;

    initial begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end

    axi_regbank dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY),
        .irq_out(irq_out)
    );

    axi_driver drv (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );

    axi_monitor mon (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWADDR(AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA(WDATA),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BVALID(BVALID),
        .BREADY(BREADY),
        .ARADDR(ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA(RDATA),
        .RVALID(RVALID),
        .RREADY(RREADY)
    );

    assertions chk (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WVALID(WVALID),
        .WREADY(WREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .irq_out(irq_out),
        .irq_en_value(dut.irq_en),
        .error_count(assertion_errors)
    );

    scoreboard sb();
    coverage cov();
    axi_sequences seq();
    rand_test rand_t();

    task apply_reset;
        begin
            drv.reset_bus();
            ARESETn = 1'b0;
            repeat (5) @(posedge ACLK);
            ARESETn = 1'b1;
            repeat (2) @(posedge ACLK);
        end
    endtask

    task run_one_test;
        input [1023:0] name;
        begin
            apply_reset();
            sb.start_test(name);

            if (name == "seq_reset")
                seq.seq_reset();
            else if (name == "seq_all_registers")
                seq.seq_all_registers();
            else if (name == "seq_irq")
                seq.seq_irq();
            else if (name == "seq_walk_ones")
                seq.seq_walk_ones();
            else if (name == "rand_test")
                rand_t.run();
            else begin
                $display("Unknown test %0s", name);
                tb_top.sb.errors = tb_top.sb.errors + 1;
            end

            repeat (3) @(posedge ACLK);
            if (assertion_errors != 0)
                tb_top.sb.errors = tb_top.sb.errors + assertion_errors;
            sb.finish_test(name, pass);
            total_tests = total_tests + 1;
            if (pass)
                total_pass = total_pass + 1;
        end
    endtask

    initial begin
        $dumpfile("results/waveform.vcd");
        $dumpvars(0, tb_top);

        total_pass = 0;
        total_tests = 0;
        ARESETn = 1'b0;

        if (!$value$plusargs("TEST=%s", testname))
            testname = "all";

        if (testname == "all") begin
            run_one_test("seq_reset");
            run_one_test("seq_all_registers");
            run_one_test("seq_irq");
            run_one_test("seq_walk_ones");
            run_one_test("rand_test");
        end else begin
            run_one_test(testname);
        end

        cov.write_report();
        sb.close_log();

        $display("Result: %0d/%0d tests passing", total_pass, total_tests);
        if (total_pass == total_tests)
            $display("FINAL PASS");
        else
            $display("FINAL FAIL");
        $finish;
    end
endmodule
