//
// This generates timing signals for the VGA interface.
// Software uploads a small microcode program that this runs. It
// contains two counters and supports two instructions:
// INITCNT: load a value into the selected counter
// LOOP: decrement the selected counter and branch to an adress if the
//       value is not zero.
// The frame_done bit will restart the microprogram from the beginning.
//
// The pixel rate (25 Mhz) is one half the input clock rate. This executes
// one instruction per pixel clock (although it's in the main clock domain,
// using pixel_en to clock gate for each pixel).
//
module vga_sequencer(
  input clk,
  input reset,
    output logic vga_vs,
    output logic vga_hs,
    output logic start_frame,
    output logic in_visible_region,
    output logic pixel_en,
  input sequencer_en,
  input prog_write_en,
  input[31:0] prog_data);

    localparam MAX_INSTRUCTIONS = 48;

    typedef logic[$clog2(MAX_INSTRUCTIONS)-1:0] progadr_t;
    typedef logic[12:0] counter_t;

    typedef enum logic {
        INITCNT,
        LOOP
    } instruction_type_t;

    typedef struct packed {
        instruction_type_t instruction_type;
        logic counter_select;
        counter_t immediate_value;

        // VGA synchronization signals
        logic vsync;
        logic hsync;
        logic frame_done;
        logic in_visible_region;
    } uop_t;

    uop_t current_uop;
    counter_t counter[2];
    counter_t counter_nxt;
    progadr_t pc;
    progadr_t pc_nxt;
    progadr_t prog_load_adr;
    logic branch_en;

    sram_1r1w #(
        .DATA_WIDTH($bits(uop_t)),
        .SIZE(MAX_INSTRUCTIONS)
    ) instruction_memory(
        .read_en(1'b1),
        .read_adr(pc_nxt),
        .read_data(current_uop),
        .write_en(prog_write_en),
        .write_adr(prog_load_adr),
        .write_data(prog_data[$bits(uop_t)-1:0]),
        .*);

    assign counter_nxt = current_uop.instruction_type == INITCNT
        ? current_uop.immediate_value
        : counter[current_uop.counter_select] - counter_t'(1);
    assign vga_vs = current_uop.vsync && sequencer_en;
    assign vga_hs = current_uop.hsync && sequencer_en;
    assign start_frame = pc == 0 && sequencer_en;
    assign in_visible_region = current_uop.in_visible_region && sequencer_en;
    assign branch_en = current_uop.frame_done || (current_uop.instruction_type == LOOP
        && counter_nxt != 0);

    always_comb
    begin
        if (pixel_en)
        begin
            if (branch_en)
                pc_nxt = progadr_t'(current_uop.immediate_value);
            else
                pc_nxt = pc + progadr_t'(1);
        end
        else
            pc_nxt = pc;
    end

    always_ff @(posedge clk, posedge reset)
    begin
        if (reset)
        begin
            counter[0] <= '0;
            counter[1] <= '0;
            pc <= '0;
            prog_load_adr <= '0;
        end
        else
        begin
            // Divide 50 Mhz clock by two to derive 25 Mhz pixel rate
            pixel_en <= !pixel_en;

            if (sequencer_en)
            begin
                if (pixel_en)
                    counter[current_uop.counter_select] <= counter_nxt;

                pc <= pc_nxt;
                prog_load_adr <= '0;
            end
            else if (prog_write_en)
            begin
                pc <= '0;
                prog_load_adr <= prog_load_adr + progadr_t'(1);
            end
        end
    end
endmodule
