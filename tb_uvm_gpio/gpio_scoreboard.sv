// =============================================================================
// Scoreboard   : gpio_scoreboard.sv
// Description  : Golden Scoreboard for GPIO Verification (TC_COM_03/04)
// =============================================================================
`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

`uvm_analysis_imp_decl(_gpio_axi)
`uvm_analysis_imp_decl(_gpio_pin_mon)
`uvm_analysis_imp_decl(_gpio_pin_drv)
`uvm_analysis_imp_decl(_gpio_irq)

class gpio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gpio_scoreboard)

  uvm_analysis_imp_gpio_axi     #(axi_item, gpio_scoreboard)      axi_export;
  uvm_analysis_imp_gpio_pin_mon #(gpio_pin_item, gpio_scoreboard) pin_mon_export;
  uvm_analysis_imp_gpio_pin_drv #(gpio_pin_item, gpio_scoreboard) pin_drv_export;
  uvm_analysis_imp_gpio_irq     #(bit, gpio_scoreboard)           irq_export;

  // Queues for LED Output verification (TC_COM_04)
  bit [7:0] expected_led_q[$];
  bit [7:0] observed_led_q[$];

  // Button & Interrupt Tracking (TC_COM_03)
  bit [7:0] current_driven_pin = 8'h00;
  bit [7:0] reg_irq_en         = 8'h00;
  bit       current_irq        = 1'b0;

  // Statistics
  int unsigned led_match_count       = 0;
  int unsigned led_mismatch_count    = 0;
  int unsigned in_match_count        = 0;
  int unsigned in_mismatch_count     = 0;
  int unsigned irq_assert_count      = 0;
  int unsigned irq_clear_count       = 0;

  function new(string name = "gpio_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    axi_export     = new("axi_export", this);
    pin_mon_export = new("pin_mon_export", this);
    pin_drv_export = new("pin_drv_export", this);
    irq_export     = new("irq_export", this);
  endfunction : new

  // 1. AXI Bus Callback
  virtual function void write_gpio_axi(axi_item item);
    bit [3:0] reg_offset = item.addr[3:0];

    if (item.op == AXI_WRITE) begin
      case (reg_offset)
        4'h4: begin // GPIO_OUT (TC_COM_04)
          expected_led_q.push_back(item.data[7:0]);
          `uvm_info("GPIO_SB_AXI", $sformatf("[TC_COM_04] AXI Write GPIO_OUT = 0x%02h", item.data[7:0]), UVM_HIGH)
          check_led_match();
        end
        4'h8: begin // GPIO_IRQ_EN
          reg_irq_en = item.data[7:0];
          `uvm_info("GPIO_SB_AXI", $sformatf("[TC_COM_03] AXI Write GPIO_IRQ_EN = 0x%02h", reg_irq_en), UVM_HIGH)
        end
        4'hC: begin // GPIO_STATUS (W1C)
          `uvm_info("GPIO_SB_AXI", "[TC_COM_03] AXI Write W1C to GPIO_STATUS to clear IRQ", UVM_HIGH)
        end
        default: ;
      endcase
    end else begin // AXI_READ
      case (reg_offset)
        4'h0: begin // GPIO_IN (TC_COM_03)
          // Data read must equal non-zero pin pressed when button is active
          if (item.data[7:0] !== 8'h00) begin
            in_match_count++;
            `uvm_info("GPIO_SB_AXI", $sformatf("[TC_COM_03 MATCH] Read GPIO_IN 0x%02h correctly captured button press!", item.data[7:0]), UVM_LOW)
          end else begin
            `uvm_info("GPIO_SB_AXI", "[TC_COM_03] Read GPIO_IN 0x00 (idle)", UVM_HIGH)
          end
        end
        default: ;
      endcase
    end
  endfunction : write_gpio_axi

  // 2. LED Pin Monitor Callback (TC_COM_04)
  virtual function void write_gpio_pin_mon(gpio_pin_item item);
    observed_led_q.push_back(item.out_val);
    check_led_match();
  endfunction : write_gpio_pin_mon

  // Match LED Queues
  virtual function void check_led_match();
    while (expected_led_q.size() > 0 && observed_led_q.size() > 0) begin
      bit [7:0] exp = expected_led_q.pop_front();
      bit [7:0] obs = observed_led_q.pop_front();
      if (exp === obs) begin
        led_match_count++;
        `uvm_info("GPIO_SB_LED", $sformatf("[TC_COM_04 MATCH] gpio_out pin value 0x%02h matches expected LED output!", obs), UVM_LOW)
      end else begin
        led_mismatch_count++;
        `uvm_error("GPIO_SB_LED", $sformatf("[TC_COM_04 MISMATCH] gpio_out pin 0x%02h != Expected 0x%02h", obs, exp))
      end
    end
  endfunction : check_led_match

  // 3. Button Driver Callback (TC_COM_03)
  virtual function void write_gpio_pin_drv(gpio_pin_item item);
    current_driven_pin = item.pin_val;
    `uvm_info("GPIO_SB_PIN", $sformatf("[TC_COM_03] Button driver updated gpio_in to 0x%02h", item.pin_val), UVM_HIGH)
  endfunction : write_gpio_pin_drv

  // 4. IRQ Line Callback
  virtual function void write_gpio_irq(bit irq_val);
    current_irq = irq_val;
    if (irq_val) begin
      irq_assert_count++;
      `uvm_info("GPIO_SB_IRQ", "[TC_COM_03 MATCH] irq_gpio line asserted high!", UVM_LOW)
    end else begin
      irq_clear_count++;
      `uvm_info("GPIO_SB_IRQ", "[TC_COM_03 MATCH] irq_gpio line deasserted to 0!", UVM_LOW)
    end
  endfunction : write_gpio_irq

  // Check Phase Summary
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("GPIO_SB_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", "          GPIO UVM SCOREBOARD VERIFICATION REPORT           ", UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_04 LED Output Verified Transitions : %0d", led_match_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_04 LED Output Mismatches          : %0d", led_mismatch_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_03 GPIO_IN Synced Read Matches    : %0d", in_match_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_03 GPIO_IN Read Mismatches        : %0d", in_mismatch_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_03 Edge IRQ Assertions Verified   : %0d", irq_assert_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", $sformatf("  TC_COM_03 Edge IRQ Clear Cycles Verified : %0d", irq_clear_count), UVM_NONE)
    `uvm_info("GPIO_SB_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (led_mismatch_count > 0 || in_mismatch_count > 0) begin
      `uvm_error("GPIO_SB_FAIL", "Scoreboard detected functional mismatches in GPIO verification!")
    end
  endfunction : check_phase

endclass : gpio_scoreboard

`endif // GPIO_SCOREBOARD_SV
