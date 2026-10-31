// =============================================================================
// Interface   : gpio_pin_if.sv
// Description : Physical Boundary Interface for GPIO Push-Buttons & LEDs
// =============================================================================
`timescale 1ns / 1ps

interface gpio_pin_if (input logic clk, input logic rst_n);

  logic [7:0] gpio_in;
  logic [7:0] gpio_out;
  logic       irq_gpio;

  // Modport for stimulus driver (drives gpio_in)
  modport driver_mp (
    input  clk, rst_n, gpio_out, irq_gpio,
    output gpio_in
  );

  // Modport for passive monitor
  modport monitor_mp (
    input  clk, rst_n, gpio_in, gpio_out, irq_gpio
  );

endinterface : gpio_pin_if
