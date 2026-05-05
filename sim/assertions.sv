module assertions (
    input wire        ACLK,
    input wire        ARESETn,
    input wire        AWVALID,
    input wire        AWREADY,
    input wire        WVALID,
    input wire        WREADY,
    input wire [1:0]  BRESP,
    input wire        BVALID,
    input wire [1:0]  RRESP,
    input wire        RVALID,
    input wire        irq_out,
    input wire [31:0] irq_en_value,
    output reg [31:0] error_count
);
    reg aw_waiting;
    reg w_waiting;

    initial begin
        error_count = 0;
        aw_waiting = 0;
        w_waiting = 0;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            aw_waiting <= 1'b0;
            w_waiting <= 1'b0;
        end else begin
            if (aw_waiting && !AWVALID) begin
                error_count <= error_count + 1;
                $display("ASSERT FAIL: AWVALID dropped before AWREADY");
            end
            if (w_waiting && !WVALID) begin
                error_count <= error_count + 1;
                $display("ASSERT FAIL: WVALID dropped before WREADY");
            end
            if (BVALID && BRESP !== 2'b00) begin
                error_count <= error_count + 1;
                $display("ASSERT FAIL: BVALID response was not OKAY");
            end
            if (RVALID && RRESP !== 2'b00) begin
                error_count <= error_count + 1;
                $display("ASSERT FAIL: RVALID response was not OKAY");
            end
            if (irq_out && irq_en_value == 32'h0) begin
                error_count <= error_count + 1;
                $display("ASSERT FAIL: irq_out asserted while IRQ_EN was zero");
            end

            aw_waiting <= AWVALID && !AWREADY;
            w_waiting <= WVALID && !WREADY;
        end
    end
endmodule
