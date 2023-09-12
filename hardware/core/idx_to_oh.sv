//
// Convert a binary index to a one hot signal (Binary encoder)
// If DIRECTION is "LSB0", index 0 is the least significant bit
// If "MSB0", index 0 is the most significant bit
//

  module idx_to_oh #(
    parameter NUM_SIGNALS = 4,
    parameter DIRECTION = "LSB0",
    parameter INDEX_WIDTH = $clog2(NUM_SIGNALS)) (
    input [INDEX_WIDTH-1:0] index,
    output logic[NUM_SIGNALS-1:0] one_hot);

    always_comb
    begin : convert
      one_hot = 0;
      if (DIRECTION == "LSB0")
        one_hot[index] = 1'b1;
      else
        one_hot[NUM_SIGNALS - 32'(index) - 1] = 1'b1;
    end

  endmodule
