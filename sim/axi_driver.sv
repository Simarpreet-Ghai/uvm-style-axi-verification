module axi_driver (
    input  wire        ACLK,
    input  wire        ARESETn,
    output reg [31:0]  AWADDR,
    output reg         AWVALID,
    input  wire        AWREADY,
    output reg [31:0]  WDATA,
    output reg [3:0]   WSTRB,
    output reg         WVALID,
    input  wire        WREADY,
    input  wire [1:0]  BRESP,
    input  wire        BVALID,
    output reg         BREADY,
    output reg [31:0]  ARADDR,
    output reg         ARVALID,
    input  wire        ARREADY,
    input  wire [31:0] RDATA,
    input  wire [1:0]  RRESP,
    input  wire        RVALID,
    output reg         RREADY
);
    initial begin
        reset_bus();
    end

    task reset_bus;
        begin
            AWADDR  = 32'h0;
            AWVALID = 1'b0;
            WDATA   = 32'h0;
            WSTRB   = 4'h0;
            WVALID  = 1'b0;
            BREADY  = 1'b0;
            ARADDR  = 32'h0;
            ARVALID = 1'b0;
            RREADY  = 1'b0;
        end
    endtask

    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        integer timeout;
        begin
            timeout = 0;
            @(posedge ACLK);
            AWADDR  = addr;
            WDATA   = data;
            WSTRB   = 4'hf;
            AWVALID = 1'b1;
            WVALID  = 1'b1;
            BREADY  = 1'b0;

            while (AWVALID || WVALID) begin
                @(posedge ACLK);
                timeout = timeout + 1;
                if (AWVALID && AWREADY)
                    AWVALID = 1'b0;
                if (WVALID && WREADY)
                    WVALID = 1'b0;
                if (timeout > 50) begin
                    $display("DRIVER ERROR: write handshake timeout addr=0x%08h", addr);
                    $finish;
                end
            end

            timeout = 0;
            while (!BVALID) begin
                @(posedge ACLK);
                timeout = timeout + 1;
                if (timeout > 50) begin
                    $display("DRIVER ERROR: write response timeout addr=0x%08h", addr);
                    $finish;
                end
            end

            BREADY = 1'b1;
            if (BRESP !== 2'b00)
                $display("DRIVER ERROR: BRESP was not OKAY addr=0x%08h resp=%b", addr, BRESP);

            @(posedge ACLK);
            BREADY = 1'b0;
            WSTRB = 4'h0;
        end
    endtask

    task axi_read;
        input  [31:0] addr;
        output [31:0] data_out;
        integer timeout;
        begin
            timeout = 0;
            @(posedge ACLK);
            ARADDR  = addr;
            ARVALID = 1'b1;
            RREADY  = 1'b0;

            while (ARVALID) begin
                @(posedge ACLK);
                timeout = timeout + 1;
                if (ARVALID && ARREADY)
                    ARVALID = 1'b0;
                if (timeout > 50) begin
                    $display("DRIVER ERROR: read address timeout addr=0x%08h", addr);
                    $finish;
                end
            end

            timeout = 0;
            while (!RVALID) begin
                @(posedge ACLK);
                timeout = timeout + 1;
                if (timeout > 50) begin
                    $display("DRIVER ERROR: read data timeout addr=0x%08h", addr);
                    $finish;
                end
            end

            data_out = RDATA;
            RREADY = 1'b1;
            if (RRESP !== 2'b00)
                $display("DRIVER ERROR: RRESP was not OKAY addr=0x%08h resp=%b", addr, RRESP);

            @(posedge ACLK);
            RREADY = 1'b0;
        end
    endtask
endmodule
