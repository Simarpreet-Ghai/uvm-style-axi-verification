module axi_regbank (
    input  wire        ACLK,
    input  wire        ARESETn,

    input  wire [31:0] AWADDR,
    input  wire        AWVALID,
    output reg         AWREADY,

    input  wire [31:0] WDATA,
    input  wire [3:0]  WSTRB,
    input  wire        WVALID,
    output reg         WREADY,

    output reg [1:0]   BRESP,
    output reg         BVALID,
    input  wire        BREADY,

    input  wire [31:0] ARADDR,
    input  wire        ARVALID,
    output reg         ARREADY,

    output reg [31:0]  RDATA,
    output reg [1:0]   RRESP,
    output reg         RVALID,
    input  wire        RREADY,

    output wire        irq_out
);
    localparam [31:0] ADDR_CTRL     = 32'h00;
    localparam [31:0] ADDR_STATUS   = 32'h04;
    localparam [31:0] ADDR_DATA_IN  = 32'h08;
    localparam [31:0] ADDR_DATA_OUT = 32'h0c;
    localparam [31:0] ADDR_IRQ_EN   = 32'h10;
    localparam [31:0] ADDR_IRQ_STAT = 32'h14;
    localparam [31:0] ADDR_SCRATCH0 = 32'h18;
    localparam [31:0] ADDR_SCRATCH1 = 32'h1c;

    reg [31:0] ctrl;
    reg [31:0] data_in;
    reg [31:0] irq_en;
    reg [31:0] irq_stat;
    reg [31:0] scratch0;
    reg [31:0] scratch1;

    reg        aw_have;
    reg [31:0] awaddr_q;
    reg        w_have;
    reg [31:0] wdata_q;
    reg [3:0]  wstrb_q;

    assign irq_out = |(irq_en & irq_stat);

    function [31:0] apply_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0]  strobe;
        begin
            apply_wstrb = old_value;
            if (strobe[0]) apply_wstrb[7:0]   = new_value[7:0];
            if (strobe[1]) apply_wstrb[15:8]  = new_value[15:8];
            if (strobe[2]) apply_wstrb[23:16] = new_value[23:16];
            if (strobe[3]) apply_wstrb[31:24] = new_value[31:24];
        end
    endfunction

    function [31:0] bit_reverse32;
        input [31:0] value;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                bit_reverse32[i] = value[31 - i];
            end
        end
    endfunction

    function [31:0] status_value;
        begin
            status_value = 32'h0;
            status_value[0] = ctrl[0];       // busy follows enable in this simple DUT
            status_value[1] = irq_stat[1];   // reserved error/status bit
            status_value[7:4] = ctrl[7:4];   // state mirrors selected mode
        end
    endfunction

    function [31:0] data_out_value;
        begin
            if (ctrl[0])
                data_out_value = bit_reverse32(data_in) ^ 32'ha5a5_5a5a;
            else
                data_out_value = 32'h0;
        end
    endfunction

    function [31:0] read_reg;
        input [31:0] addr;
        begin
            case (addr[4:0])
                ADDR_CTRL[4:0]:     read_reg = ctrl;
                ADDR_STATUS[4:0]:   read_reg = status_value();
                ADDR_DATA_IN[4:0]:  read_reg = data_in;
                ADDR_DATA_OUT[4:0]: read_reg = data_out_value();
                ADDR_IRQ_EN[4:0]:   read_reg = irq_en;
                ADDR_IRQ_STAT[4:0]: read_reg = irq_stat;
                ADDR_SCRATCH0[4:0]: read_reg = scratch0;
                ADDR_SCRATCH1[4:0]: read_reg = scratch1;
                default:            read_reg = 32'h0;
            endcase
        end
    endfunction

    task do_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        reg [31:0] next_ctrl;
        begin
            case (addr[4:0])
                ADDR_CTRL[4:0]: begin
                    next_ctrl = apply_wstrb(ctrl, data, strb);
                    ctrl <= {24'h0, next_ctrl[7:4], 2'b00, next_ctrl[0]};
                    if (next_ctrl[1]) begin
                        data_in <= 32'h0;
                        irq_stat <= 32'h0;
                        scratch0 <= 32'h0;
                        scratch1 <= 32'h0;
                    end
                end
                ADDR_STATUS[4:0]: begin
                    // STATUS is read-only.
                end
                ADDR_DATA_IN[4:0]: begin
                    data_in <= apply_wstrb(data_in, data, strb);
                    if (ctrl[0])
                        irq_stat[0] <= 1'b1;
                end
                ADDR_DATA_OUT[4:0]: begin
                    // DATA_OUT is read-only.
                end
                ADDR_IRQ_EN[4:0]: begin
                    irq_en <= apply_wstrb(irq_en, data, strb);
                end
                ADDR_IRQ_STAT[4:0]: begin
                    irq_stat <= irq_stat & ~apply_wstrb(32'h0, data, strb);
                end
                ADDR_SCRATCH0[4:0]: begin
                    scratch0 <= apply_wstrb(scratch0, data, strb);
                end
                ADDR_SCRATCH1[4:0]: begin
                    scratch1 <= apply_wstrb(scratch1, data, strb);
                end
                default: begin
                end
            endcase
        end
    endtask

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BRESP <= 2'b00;
            BVALID <= 1'b0;
            ARREADY <= 1'b0;
            RDATA <= 32'h0;
            RRESP <= 2'b00;
            RVALID <= 1'b0;

            aw_have <= 1'b0;
            awaddr_q <= 32'h0;
            w_have <= 1'b0;
            wdata_q <= 32'h0;
            wstrb_q <= 4'h0;

            ctrl <= 32'h0;
            data_in <= 32'h0;
            irq_en <= 32'h0;
            irq_stat <= 32'h0;
            scratch0 <= 32'h0;
            scratch1 <= 32'h0;
        end else begin
            AWREADY <= (!aw_have && !BVALID);
            WREADY <= (!w_have && !BVALID);
            ARREADY <= (!RVALID);

            if (!aw_have && !BVALID && AWVALID) begin
                aw_have <= 1'b1;
                awaddr_q <= AWADDR;
            end

            if (!w_have && !BVALID && WVALID) begin
                w_have <= 1'b1;
                wdata_q <= WDATA;
                wstrb_q <= WSTRB;
            end

            if (aw_have && w_have && !BVALID) begin
                do_write(awaddr_q, wdata_q, wstrb_q);
                aw_have <= 1'b0;
                w_have <= 1'b0;
                BRESP <= 2'b00;
                BVALID <= 1'b1;
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end

            if (!RVALID && ARVALID) begin
                RDATA <= read_reg(ARADDR);
                RRESP <= 2'b00;
                RVALID <= 1'b1;
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end
endmodule
