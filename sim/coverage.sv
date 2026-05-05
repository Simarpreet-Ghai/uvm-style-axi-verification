module coverage;
    integer fd;
    integer read_count;
    integer write_count;
    integer irq_seen;
    integer scratch_readback_pass;
    integer addr_accessed [0:7];
    integer i;

    initial begin
        reset();
    end

    task reset;
        begin
            read_count = 0;
            write_count = 0;
            irq_seen = 0;
            scratch_readback_pass = 0;
            for (i = 0; i < 8; i = i + 1)
                addr_accessed[i] = 0;
        end
    endtask

    task mark_addr;
        input [31:0] addr;
        integer idx;
        begin
            idx = addr[4:2];
            if (idx >= 0 && idx < 8)
                addr_accessed[idx] = 1;
        end
    endtask

    task sample_write;
        input [31:0] addr;
        begin
            write_count = write_count + 1;
            mark_addr(addr);
        end
    endtask

    task sample_read;
        input [31:0] addr;
        begin
            read_count = read_count + 1;
            mark_addr(addr);
        end
    endtask

    task sample_irq;
        input irq_value;
        begin
            if (irq_value)
                irq_seen = 1;
        end
    endtask

    task sample_scratch_pass;
        begin
            scratch_readback_pass = 1;
        end
    endtask

    function integer all_addresses_seen;
        integer j;
        begin
            all_addresses_seen = 1;
            for (j = 0; j < 8; j = j + 1) begin
                if (!addr_accessed[j])
                    all_addresses_seen = 0;
            end
        end
    endfunction

    task write_report;
        integer pass_count;
        integer total_count;
        begin
            pass_count = 0;
            total_count = 5;
            fd = $fopen("results/coverage_report.txt", "w");
            $fdisplay(fd, "AXI4-Lite Register Bank Coverage Report");
            $fdisplay(fd, "======================================");
            $fdisplay(fd, "Reads observed: %0d", read_count);
            $fdisplay(fd, "Writes observed: %0d", write_count);
            $fdisplay(fd, "All register addresses accessed: %0s", all_addresses_seen() ? "YES" : "NO");
            $fdisplay(fd, "Read operation observed: %0s", read_count > 0 ? "YES" : "NO");
            $fdisplay(fd, "Write operation observed: %0s", write_count > 0 ? "YES" : "NO");
            $fdisplay(fd, "IRQ behavior observed: %0s", irq_seen ? "YES" : "NO");
            $fdisplay(fd, "Scratch readback passed: %0s", scratch_readback_pass ? "YES" : "NO");
            $fdisplay(fd, "");
            for (i = 0; i < 8; i = i + 1)
                $fdisplay(fd, "Register index %0d accessed: %0s", i, addr_accessed[i] ? "YES" : "NO");

            if (all_addresses_seen()) pass_count = pass_count + 1;
            if (read_count > 0) pass_count = pass_count + 1;
            if (write_count > 0) pass_count = pass_count + 1;
            if (irq_seen) pass_count = pass_count + 1;
            if (scratch_readback_pass) pass_count = pass_count + 1;

            $fdisplay(fd, "");
            $fdisplay(fd, "Coverage goals hit: %0d/%0d", pass_count, total_count);
            $fclose(fd);
        end
    endtask
endmodule
