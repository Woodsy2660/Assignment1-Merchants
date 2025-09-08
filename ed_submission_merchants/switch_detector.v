module switch_detector #(
    parameter WIDTH = 18
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [WIDTH-1:0]  signal,
    output wire [WIDTH-1:0]  rise_detect,
    output wire [WIDTH-1:0]  fall_detect,
    output wire [WIDTH-1:0]  edge_detect
);
    reg [WIDTH-1:0] prev;
    always @(posedge clk) begin
        if (rst) prev <= {WIDTH{1'b0}};
        else     prev <= signal;
    end
    assign rise_detect =  signal & ~prev;
    assign fall_detect = ~signal &  prev;
    assign edge_detect = rise_detect | fall_detect;
endmodule
