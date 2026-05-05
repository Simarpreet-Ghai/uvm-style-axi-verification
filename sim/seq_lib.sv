module axi_sequences;
    localparam [31:0] ADDR_CTRL     = 32'h00;
    localparam [31:0] ADDR_STATUS   = 32'h04;
    localparam [31:0] ADDR_DATA_IN  = 32'h08;
    localparam [31:0] ADDR_DATA_OUT = 32'h0c;
    localparam [31:0] ADDR_IRQ_EN   = 32'h10;
    localparam [31:0] ADDR_IRQ_STAT = 32'h14;
    localparam [31:0] ADDR_SCRATCH0 = 32'h18;
    localparam [31:0] ADDR_SCRATCH1 = 32'h1c;

    task write_reg;
        input [31:0] addr;
        input [31:0] data;
        begin
            tb_top.drv.axi_write(addr, data);
            tb_top.sb.model_write(addr, data);
            tb_top.cov.sample_write(addr);
            @(posedge tb_top.ACLK);
            tb_top.cov.sample_irq(tb_top.irq_out);
        end
    endtask

    task read_check;
        input [1023:0] testname;
        input [31:0] addr;
        output [31:0] data;
        begin
            tb_top.drv.axi_read(addr, data);
            tb_top.cov.sample_read(addr);
            tb_top.sb.check_read(testname, addr, data);
            tb_top.cov.sample_irq(tb_top.irq_out);
        end
    endtask

    task seq_reset;
        reg [31:0] data;
        begin
            read_check("seq_reset", ADDR_CTRL, data);
            read_check("seq_reset", ADDR_STATUS, data);
            read_check("seq_reset", ADDR_DATA_IN, data);
            read_check("seq_reset", ADDR_DATA_OUT, data);
            read_check("seq_reset", ADDR_IRQ_EN, data);
            read_check("seq_reset", ADDR_IRQ_STAT, data);
            read_check("seq_reset", ADDR_SCRATCH0, data);
            read_check("seq_reset", ADDR_SCRATCH1, data);

            write_reg(ADDR_SCRATCH0, 32'hcafe_0001);
            write_reg(ADDR_SCRATCH1, 32'hcafe_0002);
            write_reg(ADDR_DATA_IN, 32'h1234_5678);
            write_reg(ADDR_CTRL, 32'h0000_0002);
            read_check("seq_reset", ADDR_CTRL, data);
            read_check("seq_reset", ADDR_DATA_IN, data);
            read_check("seq_reset", ADDR_SCRATCH0, data);
            read_check("seq_reset", ADDR_SCRATCH1, data);
        end
    endtask

    task seq_all_registers;
        reg [31:0] data;
        begin
            write_reg(ADDR_SCRATCH0, 32'h1111_2222);
            read_check("seq_all_registers", ADDR_SCRATCH0, data);
            tb_top.sb.check_value("seq_all_registers", "scratch0 mirror", 32'h1111_2222, data);
            tb_top.cov.sample_scratch_pass();

            write_reg(ADDR_SCRATCH1, 32'h3333_4444);
            read_check("seq_all_registers", ADDR_SCRATCH1, data);
            tb_top.sb.check_value("seq_all_registers", "scratch1 mirror", 32'h3333_4444, data);
            tb_top.cov.sample_scratch_pass();

            write_reg(ADDR_STATUS, 32'hffff_ffff);
            read_check("seq_all_registers", ADDR_STATUS, data);

            write_reg(ADDR_CTRL, 32'h0000_00a1);
            read_check("seq_all_registers", ADDR_CTRL, data);
            read_check("seq_all_registers", ADDR_STATUS, data);

            write_reg(ADDR_DATA_IN, 32'h0f0f_f0f0);
            read_check("seq_all_registers", ADDR_DATA_IN, data);
            read_check("seq_all_registers", ADDR_DATA_OUT, data);

            write_reg(ADDR_IRQ_EN, 32'h0000_0001);
            read_check("seq_all_registers", ADDR_IRQ_EN, data);
            read_check("seq_all_registers", ADDR_IRQ_STAT, data);
        end
    endtask

    task seq_irq;
        reg [31:0] data;
        begin
            write_reg(ADDR_IRQ_EN, 32'h0000_0001);
            write_reg(ADDR_CTRL, 32'h0000_0001);
            tb_top.sb.check_value("seq_irq", "irq before event", 32'h0, {31'h0, tb_top.irq_out});

            write_reg(ADDR_DATA_IN, 32'hdead_beef);
            repeat (2) @(posedge tb_top.ACLK);
            tb_top.cov.sample_irq(tb_top.irq_out);
            tb_top.sb.check_value("seq_irq", "irq after data event", 32'h1, {31'h0, tb_top.irq_out});
            read_check("seq_irq", ADDR_IRQ_STAT, data);

            write_reg(ADDR_IRQ_STAT, 32'h0000_0001);
            repeat (2) @(posedge tb_top.ACLK);
            tb_top.sb.check_value("seq_irq", "irq after clear", 32'h0, {31'h0, tb_top.irq_out});
            read_check("seq_irq", ADDR_IRQ_STAT, data);
        end
    endtask

    task seq_walk_ones;
        integer i;
        reg [31:0] value;
        reg [31:0] data;
        begin
            write_reg(ADDR_CTRL, 32'h0000_0001);
            for (i = 0; i < 32; i = i + 1) begin
                value = 32'h1 << i;
                write_reg(ADDR_SCRATCH0, value);
                read_check("seq_walk_ones", ADDR_SCRATCH0, data);
                tb_top.sb.check_value("seq_walk_ones", "scratch0 walking one", value, data);
                tb_top.cov.sample_scratch_pass();

                write_reg(ADDR_SCRATCH1, ~value);
                read_check("seq_walk_ones", ADDR_SCRATCH1, data);
                tb_top.sb.check_value("seq_walk_ones", "scratch1 walking one", ~value, data);

                write_reg(ADDR_DATA_IN, value);
                read_check("seq_walk_ones", ADDR_DATA_OUT, data);
            end
        end
    endtask
endmodule
