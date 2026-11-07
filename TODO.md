# RISC-V Real-Time Oscilloscope SoC — UVM Verification TODO & Roadmap

This tracking document outlines the verification status, completed milestones, remaining peripheral Verification IPs (VIPs), and test cases according to the SoC Verification Test Plan ([`doc/SoC_UVM_Test_Plan.xlsx`](file:///home/student/Documents/honours_project_soc/doc/SoC_UVM_Test_Plan.xlsx)).

---

## 1. Executive Status & Progress Scorecard

| Peripheral Subsystem | Verification IP / Environment | Target Test Plan IDs | SVA Assertions | Verification Status | VCS Simulation Target |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **16550 UART** | [`tb_uvm_uart/`](file:///home/student/Documents/honours_project_soc/tb_uvm_uart/) | `TC_COM_01`, `TC_COM_02`, `TC_COM_03` | Baud & framing assertions | **PASSED (100%)** | `make uvm-uart` |
| **GPIO Controller** | [`tb_uvm_gpio/`](file:///home/student/Documents/honours_project_soc/tb_uvm_gpio/) | `TC_COM_03`, `TC_COM_04` | Pin sync & IRQ check | **PASSED (100%)** | `make uvm-gpio` |
| **System Timer** | [`tb_uvm_timer/`](file:///home/student/Documents/honours_project_soc/tb_uvm_timer/) | `TC_ACQ_01` | Cycle-accurate down-counter | **PASSED (100%)** | `make uvm-timer` |
| **Watchdog Monitor**| [`tb_uvm_watchdog/`](file:///home/student/Documents/honours_project_soc/tb_uvm_watchdog/) | `TC_WDT_01` | `SVA_WDT_01`, `SVA_WDT_02` | **PASSED (100%)** | `make uvm-watchdog` |
| **SPI Controller** | [`tb_uvm_spi/`](file:///home/student/Documents/honours_project_soc/tb_uvm_spi/) | `TC_ACQ_02`..`TC_ACQ_06` | `SVA_SPI_01`, `SVA_SPI_02` | **PASSED (100%)** | `make uvm-spi` |
| **FIR Filter** | [`tb_uvm_fir/`](file:///home/student/Documents/honours_project_soc/tb_uvm_fir/) | `TC_FIR_01`..`TC_FIR_06` | `SVA_FIR_01`, `SVA_FIR_02` | **PASSED (100%)** | `make uvm-fir` |
| **Sample Buffer** | [`tb_uvm_sample_buffer/`](file:///home/student/Documents/honours_project_soc/tb_uvm_sample_buffer/) | `TC_BUF_01`..`TC_BUF_05` | `SVA_BUF_01`, `SVA_BUF_02`, `SVA_CDC_01` | **PASSED (100%)** | `make uvm-sample-buffer`|
| **VGA Controller** | [`tb_uvm_vga/`](file:///home/student/Documents/honours_project_soc/tb_uvm_vga/) | `TC_VGA_01`..`TC_VGA_06` | `SVA_VGA_01`, `SVA_VGA_02` | **PASSED (100%)** | `make uvm-vga` |
| **DMA Controller** | [`tb_uvm_dma/`](file:///home/student/Documents/honours_project_soc/tb_uvm_dma/) | `TC_DMA_01`..`TC_DMA_07` | `SVA_DMA_01`, `SVA_DMA_02` | **PASSED (100%)** | `make uvm-dma` |
| **Closed-Loop SoC**| Top Integration Suite | `TC_SYS_01` | 25 Full System Assertions | **PASSED (100%)** | `make soc` / `make hello` |

---

## 2. Key Accomplishments & Hardware Bugfixes

1. **UVM VIP Infrastructure & Automation:**
   - Designed and built CSV signal specification workflow: `python uvm_testbench_generator.py <protocol> <signals.csv>`.
   - Signal specifications generated for all peripherals: `axi_signals.csv`, `gpio_signals.csv`, `timer_signals.csv`, `watchdog_signals.csv`, `spi_signals.csv`, `fir_signals.csv`, `sample_buffer_signals.csv`, `vga_signals.csv`, `dma_signals.csv`.
   - Built modular, reusable AXI-Lite VIP in [`axi_uvm_tb/`](file:///home/student/Documents/honours_project_soc/axi_uvm_tb/) supporting concurrent single-cycle address/data/response handshakes.

2. **16550 UART VIP & RTL Bug Fix:**
   - Discovered and corrected off-by-one baud divider mismatch in [`rtl/axi_uart/rtl/uart_transmitter.v`](file:///home/student/Documents/honours_project_soc/rtl/axi_uart/rtl/uart_transmitter.v) (`counter_int >= baud_div_i` fixed to `counter_int >= (baud_div_i - 1)`).
   - Fully verified: `TC_COM_01` (115200 framing), `TC_COM_02` (RX FIFO & IRQ watermark), `TC_COM_03` (bidirectional transmission).

3. **GPIO Controller VIP:**
   - Created dedicated `gpio_pin_if.sv`, `gpio_pin_driver.sv`, `gpio_pin_monitor.sv`, `gpio_scoreboard.sv`.
   - Fully verified: `TC_COM_03` (button synchronizer & pin-change IRQ), `TC_COM_04` (LED output drive).

4. **System Timer VIP:**
   - Created dedicated `timer_pulse_if.sv`, `timer_pulse_monitor.sv`, `timer_scoreboard.sv`, `timer_coverage.sv`.
   - Fully verified: `TC_ACQ_01` (cycle-accurate sample rate pacing, auto-reload, W1C IRQ clear).

5. **Watchdog Safety Monitor VIP:**
   - Created dedicated `wdt_safety_if.sv`, `wdt_safety_monitor.sv`, `watchdog_scoreboard.sv`.
   - Fully verified: `TC_WDT_01` (keep-alive kicks prevent reset; timeout trips NMI pre-warning and hard reset).
   - Formally verified `SVA_WDT_02`: `nmi_prewarn` pulses strictly 1 clock cycle prior to `wdt_reset_out`.

6. **SPI Master Controller VIP & RTL Fixes:**
   - Fixed hardware bug in [`rtl/spi_controller/spi_controller.sv`](file:///home/student/Documents/honours_project_soc/rtl/spi_controller/spi_controller.sv): missing reset for `fifo_wr_ptr` and `fifo_rd_ptr` in `if (!rst_n)`.
   - Added hardware support for manual SPI command transmission (`start_transfer` in manual mode).
   - Built reactive ADC slave VIP (`spi_adc_driver.sv`) simulating 16-bit analog sampling.
   - Fully verified:
     - `TC_ACQ_02`: Autonomous SPI hardware auto-trigger via `sample_tick`.
     - `TC_ACQ_03`: SPI prescaler clock division and 50% duty cycle across prescalers 2, 4, 8 (`SVA_SPI_02`).
     - `TC_ACQ_04`: 32-entry sample FIFO watermark, overflow drop of 33rd sample, and in-order drain.
     - `TC_ACQ_05`: Manual command word transmission on MOSI.
     - `TC_ACQ_06`: CS_N lead and trail margins (>20ns) compliance.
     - `SVA_SPI_01`: Exactly 16 SCK cycles per conversion.

7. **16-Tap FIR Digital Filter VIP:**
   - Created dedicated `fir_sample_if.sv`, `fir_sample_driver.sv`, `fir_sample_monitor.sv`, `fir_scoreboard.sv`.
   - Scoreboard implements exact Q1.15 fixed-point reference MAC golden model and dynamic tap mask.
   - Fully verified:
     - `TC_FIR_01`: Impulse Response Matching Q1.15 (`0x7FFF` impulse input).
     - `TC_FIR_02`: Hardware Bypass vs Active Mode (`SVA_FIR_02`: 1-cycle raw latency).
     - `TC_FIR_03`: Dynamic Tap Scaling (runtime scaling from 4 to 12 active taps).
     - `TC_FIR_04`: Overflow and Saturation Clamping (`SVA_FIR_01`: clamping to `+32767` / `-32768`).
     - `TC_FIR_05`: Low-Pass Noise Attenuation vs Golden Model.
     - `TC_FIR_06`: Memory-Mapped Direct Sample Injection.

8. **Dual-Port Ping-Pong Sample Buffer & CDC VIP:**
   - Created dedicated `sbuf_ram_if.sv`, `sbuf_vga_driver.sv`, `sbuf_monitor.sv`, `sbuf_scoreboard.sv`.
   - Discovered and resolved CDC bank swap timing corner case: hardware now latches bank swap requests atomically during `vsync_tick` without tearing or corrupting in-flight DMA sample collection.
   - Fully verified:
     - `TC_BUF_01`: Tear-Free Rotation Synchronized to VSYNC (`SVA_BUF_01`, `SVA_BUF_02`).
     - `TC_BUF_02`: Write-Hold Freeze Mode (`SBUF_CTRL.HOLD = 1`).
     - `TC_BUF_03`: Concurrent 3-Port Access Stress (DMA Port A write, VGA Port B read, CPU AXI read).
     - `TC_BUF_04`: Manual Bank Swap Override.
     - `TC_BUF_05`: Asynchronous CDC SVA Verification (`SVA_CDC_01`: 2-stage synchronizer).

9. **VGA Oscilloscope Controller VIP:**
   - Created dedicated `vga_pixel_if.sv`, `vga_monitor.sv`, `vga_scoreboard.sv`, `vga_coverage.sv`.
   - Resolved 1-cycle pipeline delay alignment between internal counters and registered RGB/sync pins.
   - Fully verified:
     - `TC_VGA_01`: VESA 640x480 @ 60Hz Timing Compliance (`SVA_VGA_01`, `SVA_VGA_02`: zero blanking).
     - `TC_VGA_02`: Rising and Falling Trigger Comparator.
     - `TC_VGA_03`: Holdoff Timeout & Free-Run Fallback.
     - `TC_VGA_04`: Volts/Div (VDIV) & Time/Div (TDIV) Scaling Sweep.
     - `TC_VGA_05`: Software UI Color Palette Customization (Trace, Grid, BG, Cursor RGB444).
     - `TC_VGA_06`: Voltage Cursors A & B Overlay.

10. **Autonomous DMA Controller VIP:**
    - Created dedicated `dma_stream_if.sv`, `dma_stream_driver.sv`, `dma_axi_master_responder.sv`, `dma_monitor.sv`, `dma_scoreboard.sv`.
    - Implemented reactive AXI4 master slave responder modeling system crossbar memory with 64-cycle abort guard.
    - Fully verified:
      - `TC_DMA_01`: Streaming Pipeline (ADC/FIR -> SBUF) with automatic ping-pong buffer swap (`SVA_DMA_01`).
      - `TC_DMA_02`: Universal AXI4 Master Block Move across Crossbar (`SVA_DMA_02`).
      - `TC_DMA_03`: Rate-Paced vs Free-Running Transfer.
      - `TC_DMA_04`: Continuous Auto-Reload Ring Buffer Mode.
      - `TC_DMA_05`: Bus Stall Timeout Abort & Watchdog Recovery.
      - `TC_DMA_06`: Sample Underrun Handling and SLVERR Recovery.
      - `TC_DMA_07`: Fixed vs Incrementing Addressing Modes.

11. **Closed-Loop SoC System Integration & Live C Firmware:**
    - End-to-end SoC verification passing 25/25 system assertions (`make soc`).
    - Real-time C Firmware compilation and execution over 16550 UART live terminal (`make hello`).

---

## 3. Remaining Tasks (TODO List)

### Priority 4: FIR Digital Filter VIP (`tb_uvm_fir/`)
- [x] Create dedicated testbench directory `tb_uvm_fir/`.
- [x] Implement `fir_sample_if.sv` (streaming sample input, output, valid strobes).
- [x] Implement FIR driver and reference Q1.15 MAC golden model in scoreboard.
- [x] Implement UVM sequences & tests:
  - [x] `TC_FIR_01`: Impulse Response Matching Q1.15 (impulse input `0x7FFF`, verify tap coefficients).
  - [x] `TC_FIR_02`: Hardware Bypass vs Active Mode (`SVA_FIR_02`: 1-cycle latency raw pass-through).
  - [x] `TC_FIR_03`: Runtime Tap Scaling (1 to 16 active taps dynamic reconfiguration).
  - [x] `TC_FIR_04`: Accumulator Overflow & Saturation Clamping (`SVA_FIR_01`: clamping to +32767 / -32768).
  - [x] `TC_FIR_05`: Low-Pass Noise Attenuation vs Golden Model.
  - [x] `TC_FIR_06`: Memory-Mapped Direct Sample Injection.
- [x] Add `make uvm-fir` targets to root `Makefile` and verify with VCS.

### Priority 5: Dual-Port Ping-Pong Sample Buffer & CDC VIP (`tb_uvm_sample_buffer/`)
- [x] Create dedicated testbench directory `tb_uvm_sample_buffer/`.
- [x] Implement dual-port RAM interface & VGA VSYNC synchronizer VIP.
- [x] Implement UVM sequences & tests:
  - [x] `TC_BUF_01`: Tear-Free Rotation Synchronized to VSYNC (`SVA_BUF_01`, `SVA_BUF_02`).
  - [x] `TC_BUF_02`: Write-Hold Freeze Mode (`SBUF_CTRL.HOLD = 1`).
  - [x] `TC_BUF_03`: Concurrent 3-Port Access Stress (DMA Port A write, VGA Port B read, CPU AXI read).
  - [x] `TC_BUF_04`: Manual Bank Swap Override.
  - [x] `TC_BUF_05`: Asynchronous CDC SVA Verification (`SVA_CDC_01`: 2-stage synchronizer).
- [x] Add `make uvm-sample-buffer` targets to root `Makefile` and verify with VCS.

### Priority 6: VGA Oscilloscope Visualization VIP (`tb_uvm_vga/`)
- [x] Create dedicated testbench directory `tb_uvm_vga/`.
- [x] Implement VESA 640x480 timing checker VIP.
- [x] Implement UVM sequences & tests:
  - [x] `TC_VGA_01`: 640x480 @ 60Hz Timing Compliance (`SVA_VGA_01`: HSYNC 31.77us, VSYNC 16.68ms, `SVA_VGA_02`: zero blanking).
  - [x] `TC_VGA_02`: Rising/Falling Trigger Comparator.
  - [x] `TC_VGA_03`: Holdoff Timeout & Free-Run Fallback.
  - [x] `TC_VGA_04`: Volts/Div (VDIV) & Time/Div (TDIV) Scaling Sweep.
  - [x] `TC_VGA_05`: Software UI Color Customization (Trace, Grid, BG, Cursor RGB444).
  - [x] `TC_VGA_06`: Voltage Cursors A & B Overlay.
- [x] Add `make uvm-vga` targets to root `Makefile` and verify with VCS.

### Priority 7: Autonomous DMA Controller VIP (`tb_uvm_dma/`)
- [x] Create dedicated testbench directory `tb_uvm_dma/`.
- [x] Implement DMA CSR VIP and reactive AXI memory responder for Crossbar Port S03.
- [x] Implement UVM sequences & tests:
  - [x] `TC_DMA_01`: Streaming Pipeline to Sample Buffer (`SVA_DMA_01`: `buf_swap_req` after DMA_LEN).
  - [x] `TC_DMA_02`: Universal AXI4 Master Block Move across Crossbar (`SVA_DMA_02`).
  - [x] `TC_DMA_03`: Rate-Paced vs Free-Running Sweep.
  - [x] `TC_DMA_04`: Continuous Auto-Reload Streaming.
  - [x] `TC_DMA_05`: Transfer Cycle Timeout & Abort.
  - [x] `TC_DMA_06`: Sample Underrun Handling.
  - [x] `TC_DMA_07`: Address Increment vs Fixed Modes.
- [x] Add `make uvm-dma` targets to root `Makefile` and verify with VCS.

### Priority 8: Full SoC Closed-Loop Verification (`TC_SYS_01`)
- [x] Execute `TC_SYS_01` end-to-end acquisition, filtering, sample buffering, display rendering, and telemetry over UART.
- [x] Confirm all 25 top-level SVA assertions pass with 0 errors.

---

## 4. Quick Verification Commands

```bash
# Run All UART VIP Tests (TC_COM_01, TC_COM_02, TC_COM_03)
make uvm-uart

# Run All GPIO VIP Tests (TC_COM_03, TC_COM_04)
make uvm-gpio

# Run System Timer VIP Tests (TC_ACQ_01)
make uvm-timer

# Run Watchdog Safety Monitor VIP Tests (TC_WDT_01, SVA_WDT_01/02)
make uvm-watchdog

# Run SPI Controller VIP Tests (TC_ACQ_02..06, SVA_SPI_01/02)
make uvm-spi

# Run FIR Digital Filter VIP Tests (TC_FIR_01..06, SVA_FIR_01/02)
make uvm-fir

# Run Dual-Port Sample Buffer & CDC VIP Tests (TC_BUF_01..05, SVA_BUF_01/02, SVA_CDC_01)
make uvm-sample-buffer

# Run VGA Oscilloscope Controller VIP Tests (TC_VGA_01..06, SVA_VGA_01/02)
make uvm-vga

# Run Autonomous DMA Controller VIP Tests (TC_DMA_01..07, SVA_DMA_01/02)
make uvm-dma

# Run Top-Level SoC Integration Suite (25/25 assertions)
make soc

# Run C Firmware UART Hello World Live Terminal
make hello
```
