// =============================================================================
// Environment  : fir_env.sv
// Description  : UVM Environment for FIR Digital Filter Verification
// =============================================================================
`ifndef FIR_ENV_SV
`define FIR_ENV_SV

class fir_env extends uvm_env;
  `uvm_component_utils(fir_env)

  axi_agent        axi_agt;
  fir_sample_agent sample_agt;
  fir_scoreboard   sb;
  fir_coverage     cov;

  function new(string name = "fir_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_agt    = axi_agent::type_id::create("axi_agt", this);
    sample_agt = fir_sample_agent::type_id::create("sample_agt", this);
    sb         = fir_scoreboard::type_id::create("sb", this);
    cov        = fir_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axi_agt.ap.connect(sb.axi_export);
    axi_agt.ap.connect(cov.axi_cov_export);

    sample_agt.drv.drv_ap.connect(sb.drv_export);
    sample_agt.mon.item_collected_port.connect(sb.mon_export);
    sample_agt.mon.item_collected_port.connect(cov.analysis_export);
    sample_agt.mon.irq_ap.connect(sb.irq_export);
  endfunction

endclass : fir_env

`endif // FIR_ENV_SV
