module axi_monitor (
    input wire        ACLK,
    input wire        ARESETn,
    input wire [31:0] AWADDR,
    input wire        AWVALID,
    input wire        AWREADY,
    input wire [31:0] WDATA,
    input wire        WVALID,
    input wire        WREADY,
    input wire        BVALID,
    input wire        BREADY,
    input wire [31:0] ARADDR,
    input wire        ARVALID,
    input wire        ARREADY,
    input wire [31:0] RDATA,
    input wire        RVALID,
    input wire        RREADY
);
    reg        aw_seen;
    reg        w_seen;
    reg [31:0] awaddr_q;
    reg [31:0] wdata_q;
    reg [31:0] araddr_q;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            aw_seen <= 1'b0;
            w_seen <= 1'b0;
            awaddr_q <= 32'h0;
            wdata_q <= 32'h0;
            araddr_q <= 32'h0;
        end else begin
            if (AWVALID && AWREADY) begin
                aw_seen <= 1'b1;
                awaddr_q <= AWADDR;
            end
            if (WVALID && WREADY) begin
                w_seen <= 1'b1;
                wdata_q <= WDATA;
            end
            if (BVALID && BREADY && aw_seen && w_seen) begin
                $display("MON write addr=0x%08h data=0x%08h", awaddr_q, wdata_q);
                tb_top.sb.log_observed_write(awaddr_q, wdata_q);
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
            end

            if (ARVALID && ARREADY)
                araddr_q <= ARADDR;
            if (RVALID && RREADY) begin
                $display("MON read addr=0x%08h data=0x%08h", araddr_q, RDATA);
                tb_top.sb.log_observed_read(araddr_q, RDATA);
            end
        end
    end
endmodule
