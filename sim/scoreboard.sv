module scoreboard;
    localparam [31:0] ADDR_CTRL     = 32'h00;
    localparam [31:0] ADDR_STATUS   = 32'h04;
    localparam [31:0] ADDR_DATA_IN  = 32'h08;
    localparam [31:0] ADDR_DATA_OUT = 32'h0c;
    localparam [31:0] ADDR_IRQ_EN   = 32'h10;
    localparam [31:0] ADDR_IRQ_STAT = 32'h14;
    localparam [31:0] ADDR_SCRATCH0 = 32'h18;
    localparam [31:0] ADDR_SCRATCH1 = 32'h1c;

    integer log_fd;
    integer errors;
    integer test_errors;

    reg [31:0] ref_ctrl;
    reg [31:0] ref_data_in;
    reg [31:0] ref_irq_en;
    reg [31:0] ref_irq_stat;
    reg [31:0] ref_scratch0;
    reg [31:0] ref_scratch1;

    initial begin
        log_fd = $fopen("results/scoreboard_log.csv", "w");
        $fdisplay(log_fd, "kind,test,addr,expected,actual,result");
        reset_model();
        errors = 0;
        test_errors = 0;
    end

    function [31:0] bit_reverse32;
        input [31:0] value;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1)
                bit_reverse32[i] = value[31 - i];
        end
    endfunction

    function [31:0] status_value;
        begin
            status_value = 32'h0;
            status_value[0] = ref_ctrl[0];
            status_value[1] = ref_irq_stat[1];
            status_value[7:4] = ref_ctrl[7:4];
        end
    endfunction

    function [31:0] data_out_value;
        begin
            if (ref_ctrl[0])
                data_out_value = bit_reverse32(ref_data_in) ^ 32'ha5a5_5a5a;
            else
                data_out_value = 32'h0;
        end
    endfunction

    function [31:0] expected_read;
        input [31:0] addr;
        begin
            case (addr[4:0])
                ADDR_CTRL[4:0]:     expected_read = ref_ctrl;
                ADDR_STATUS[4:0]:   expected_read = status_value();
                ADDR_DATA_IN[4:0]:  expected_read = ref_data_in;
                ADDR_DATA_OUT[4:0]: expected_read = data_out_value();
                ADDR_IRQ_EN[4:0]:   expected_read = ref_irq_en;
                ADDR_IRQ_STAT[4:0]: expected_read = ref_irq_stat;
                ADDR_SCRATCH0[4:0]: expected_read = ref_scratch0;
                ADDR_SCRATCH1[4:0]: expected_read = ref_scratch1;
                default:            expected_read = 32'h0;
            endcase
        end
    endfunction

    task reset_model;
        begin
            ref_ctrl = 32'h0;
            ref_data_in = 32'h0;
            ref_irq_en = 32'h0;
            ref_irq_stat = 32'h0;
            ref_scratch0 = 32'h0;
            ref_scratch1 = 32'h0;
        end
    endtask

    task start_test;
        input [1023:0] testname;
        begin
            reset_model();
            test_errors = errors;
            $display("[%0s] START", testname);
            $fdisplay(log_fd, "TEST,%0s,0x00000000,0x00000000,0x00000000,START", testname);
        end
    endtask

    task finish_test;
        input  [1023:0] testname;
        output integer pass;
        begin
            pass = (errors == test_errors);
            if (pass)
                $display("[%0s] PASS", testname);
            else
                $display("[%0s] FAIL", testname);
            $fdisplay(log_fd, "TEST,%0s,0x00000000,0x00000000,0x00000000,%0s",
                      testname, pass ? "PASS" : "FAIL");
        end
    endtask

    task model_write;
        input [31:0] addr;
        input [31:0] data;
        reg [31:0] next_ctrl;
        begin
            case (addr[4:0])
                ADDR_CTRL[4:0]: begin
                    next_ctrl = data;
                    ref_ctrl = {24'h0, next_ctrl[7:4], 2'b00, next_ctrl[0]};
                    if (next_ctrl[1]) begin
                        ref_data_in = 32'h0;
                        ref_irq_stat = 32'h0;
                        ref_scratch0 = 32'h0;
                        ref_scratch1 = 32'h0;
                    end
                end
                ADDR_STATUS[4:0]: begin
                end
                ADDR_DATA_IN[4:0]: begin
                    ref_data_in = data;
                    if (ref_ctrl[0])
                        ref_irq_stat[0] = 1'b1;
                end
                ADDR_DATA_OUT[4:0]: begin
                end
                ADDR_IRQ_EN[4:0]: begin
                    ref_irq_en = data;
                end
                ADDR_IRQ_STAT[4:0]: begin
                    ref_irq_stat = ref_irq_stat & ~data;
                end
                ADDR_SCRATCH0[4:0]: begin
                    ref_scratch0 = data;
                end
                ADDR_SCRATCH1[4:0]: begin
                    ref_scratch1 = data;
                end
                default: begin
                end
            endcase
            $fdisplay(log_fd, "WRITE,model,0x%08h,0x%08h,0x%08h,UPDATE", addr, data, data);
        end
    endtask

    task check_read;
        input [1023:0] testname;
        input [31:0] addr;
        input [31:0] actual;
        reg [31:0] expected;
        begin
            expected = expected_read(addr);
            if (actual === expected) begin
                $display("PASS read addr=0x%08h data=0x%08h", addr, actual);
                $fdisplay(log_fd, "READ,%0s,0x%08h,0x%08h,0x%08h,PASS",
                          testname, addr, expected, actual);
            end else begin
                errors = errors + 1;
                $display("FAIL read addr=0x%08h expected=0x%08h actual=0x%08h",
                         addr, expected, actual);
                $fdisplay(log_fd, "READ,%0s,0x%08h,0x%08h,0x%08h,FAIL",
                          testname, addr, expected, actual);
            end
        end
    endtask

    task check_value;
        input [1023:0] testname;
        input [1023:0] label;
        input [31:0] expected;
        input [31:0] actual;
        begin
            if (actual === expected) begin
                $display("PASS %0s expected=0x%08h actual=0x%08h", label, expected, actual);
                $fdisplay(log_fd, "CHECK,%0s,0x00000000,0x%08h,0x%08h,PASS",
                          testname, expected, actual);
            end else begin
                errors = errors + 1;
                $display("FAIL %0s expected=0x%08h actual=0x%08h", label, expected, actual);
                $fdisplay(log_fd, "CHECK,%0s,0x00000000,0x%08h,0x%08h,FAIL",
                          testname, expected, actual);
            end
        end
    endtask

    task log_observed_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            $fdisplay(log_fd, "MON_WRITE,monitor,0x%08h,0x%08h,0x%08h,OBSERVED", addr, data, data);
        end
    endtask

    task log_observed_read;
        input [31:0] addr;
        input [31:0] data;
        begin
            $fdisplay(log_fd, "MON_READ,monitor,0x%08h,0x%08h,0x%08h,OBSERVED", addr, data, data);
        end
    endtask

    task close_log;
        begin
            $fclose(log_fd);
        end
    endtask
endmodule
