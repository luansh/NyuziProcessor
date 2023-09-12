//
// Programmable interrupt timer
//

module timer
    #(parameter BASE_ADDRESS = 0)

    (input clk,
  input reset,

    // IO bus interface
    io_bus_interface.slave    io_bus,

    // Interrupt
    output logic timer_interrupt);

    logic[31:0] counter;

    assign io_bus.read_data = '0;

    always_ff @(posedge clk, posedge reset)
    begin
        if (reset)
        begin
            /*AUTORESET*/
            // Beginning of autoreset for uninitialized flops
            counter <= '0;
            timer_interrupt <= '0;
            // End of automatics
        end
        else
        begin
            if (io_bus.write_en && io_bus.address == BASE_ADDRESS)
                counter <= io_bus.write_data;
            else if (counter != 0)
                counter <= counter - 1;

            timer_interrupt <= counter == 0;
        end
    end
endmodule
