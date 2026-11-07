// =============================================================================
// Driver       : vga_sbuf_driver.sv
// Description  : Reactive Driver feeding synthetic samples into VGA Controller
// =============================================================================
`ifndef VGA_SBUF_DRIVER_SV
`define VGA_SBUF_DRIVER_SV

class vga_sbuf_driver extends uvm_driver;
  `uvm_component_utils(vga_sbuf_driver)

  virtual vga_pixel_if vif;

  // Waveform generation mode: 0=zero, 1=DC offset, 2=sine/cosine, 3=square
  int waveform_mode = 2;
  bit signed [15:0] dc_level = 16'sd0;

  function new(string name = "vga_sbuf_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vga_pixel_if)::get(this, "", "vga_vif", vif)) begin
      `uvm_fatal("NOVIF", "virtual vga_pixel_if not found in config_db")
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.sbuf_rdata <= 16'sd0;

    @(posedge vif.rst_vga_n);

    forever begin
      @(posedge vif.clk_vga);
      case (waveform_mode)
        0: vif.sbuf_rdata <= 16'sd0;
        1: vif.sbuf_rdata <= dc_level;
        2: begin
          // Triangle / stepped waveform across 640 screen pixels
          int x_pos = vif.sbuf_raddr % 640;
          vif.sbuf_rdata <= (x_pos < 320) ? (x_pos * 40 - 6400) : ((640 - x_pos) * 40 - 6400);
        end
        3: begin
          // Square wave (period 100 pixels)
          vif.sbuf_rdata <= ((vif.sbuf_raddr % 100) < 50) ? 16'sd8000 : -16'sd8000;
        end
        default: vif.sbuf_rdata <= 16'sd0;
      endcase
    end
  endtask

endclass : vga_sbuf_driver

`endif // VGA_SBUF_DRIVER_SV
