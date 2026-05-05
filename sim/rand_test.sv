module rand_test;
    localparam [31:0] ADDR_CTRL     = 32'h00;
    localparam [31:0] ADDR_STATUS   = 32'h04;
    localparam [31:0] ADDR_DATA_IN  = 32'h08;
    localparam [31:0] ADDR_DATA_OUT = 32'h0c;
    localparam [31:0] ADDR_IRQ_EN   = 32'h10;
    localparam [31:0] ADDR_IRQ_STAT = 32'h14;
    localparam [31:0] ADDR_SCRATCH0 = 32'h18;
    localparam [31:0] ADDR_SCRATCH1 = 32'h1c;

    function [31:0] random_read_addr;
        input integer sel;
        begin
            case (sel % 8)
                0: random_read_addr = ADDR_CTRL;
                1: random_read_addr = ADDR_STATUS;
                2: random_read_addr = ADDR_DATA_IN;
                3: random_read_addr = ADDR_DATA_OUT;
                4: random_read_addr = ADDR_IRQ_EN;
                5: random_read_addr = ADDR_IRQ_STAT;
                6: random_read_addr = ADDR_SCRATCH0;
                default: random_read_addr = ADDR_SCRATCH1;
            endcase
        end
    endfunction

    function [31:0] random_write_addr;
        input integer sel;
        begin
            case (sel % 6)
                0: random_write_addr = ADDR_CTRL;
                1: random_write_addr = ADDR_DATA_IN;
                2: random_write_addr = ADDR_IRQ_EN;
                3: random_write_addr = ADDR_IRQ_STAT;
                4: random_write_addr = ADDR_SCRATCH0;
                default: random_write_addr = ADDR_SCRATCH1;
            endcase
        end
    endfunction

    task run;
        integer i;
        reg [31:0] addr;
        reg [31:0] data;
        reg [31:0] read_data;
        begin
            for (i = 0; i < 100; i = i + 1) begin
                if (($urandom % 2) == 0) begin
                    addr = random_write_addr($urandom);
                    data = $urandom;
                    if (addr == ADDR_CTRL)
                        data = {24'h0, data[7:4], 2'b00, data[0]};
                    if (addr == ADDR_IRQ_STAT)
                        data = data & 32'h0000_0003;
                    tb_top.seq.write_reg(addr, data);
                end else begin
                    addr = random_read_addr($urandom);
                    tb_top.seq.read_check("rand_test", addr, read_data);
                end
            end

            tb_top.seq.write_reg(ADDR_SCRATCH0, 32'h55aa_0123);
            tb_top.seq.read_check("rand_test", ADDR_SCRATCH0, read_data);
            tb_top.sb.check_value("rand_test", "random scratch readback", 32'h55aa_0123, read_data);
            tb_top.cov.sample_scratch_pass();

            tb_top.seq.write_reg(ADDR_IRQ_EN, 32'h0000_0001);
            tb_top.seq.write_reg(ADDR_CTRL, 32'h0000_0001);
            tb_top.seq.write_reg(ADDR_DATA_IN, 32'h1357_2468);
            repeat (2) @(posedge tb_top.ACLK);
            tb_top.cov.sample_irq(tb_top.irq_out);
            tb_top.sb.check_value("rand_test", "random irq event", 32'h1, {31'h0, tb_top.irq_out});
            tb_top.seq.write_reg(ADDR_IRQ_STAT, 32'h0000_0001);
        end
    endtask
endmodule
