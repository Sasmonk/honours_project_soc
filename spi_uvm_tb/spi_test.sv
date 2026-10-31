// =============================================================================
// Test Lib     : spi_test.sv
// Description  : Base Test and Directed Verification Scenarios
// =============================================================================
`ifndef SPI_TEST_SV
`define SPI_TEST_SV

class spi_base_test extends uvm_test;
  `uvm_component_utils(spi_base_test)

  spi_env env;

  function new(string name = "spi_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    uvm_top.set_report_verbosity_level_hier(UVM_LOW);
  endtask : run_phase
endclass : spi_base_test

// Directed Sanity Test
class spi_sanity_test extends spi_base_test;
  `uvm_component_utils(spi_sanity_test)

  function new(string name = "spi_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    axi_write_seq wr_seq;
    axi_read_seq  rd_seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting AXI Directed Read/Write Sanity Test...", UVM_LOW)

    // Write 0x12345678 to Address 0x1000
    wr_seq = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr = 32'h0000_1000;
    wr_seq.data = 32'h1234_5678;
    wr_seq.start(env.agent.seqr);

    // Read back from Address 0x1000
    rd_seq = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_1000;
    rd_seq.start(env.agent.seqr);

    // Write 0xCAFEBABE to Address 0x2000
    wr_seq = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr = 32'h0000_2000;
    wr_seq.data = 32'hCAFE_BABE;
    wr_seq.start(env.agent.seqr);

    // Read back from Address 0x2000
    rd_seq = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_2000;
    rd_seq.start(env.agent.seqr);

    #100ns;
    phase.drop_objection(this);
  endtask : run_phase
endclass : spi_sanity_test

// Random Burst Test
class spi_random_test extends spi_base_test;
  `uvm_component_utils(spi_random_test)

  function new(string name = "spi_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    axi_rand_burst_seq rseq;
    phase.raise_objection(this);
    `uvm_info("TEST", "Starting AXI Randomized Burst Verification...", UVM_LOW)

    rseq = axi_rand_burst_seq::type_id::create("rseq");
    rseq.count = 25;
    rseq.start(env.agent.seqr);

    #100ns;
    phase.drop_objection(this);
  endtask : run_phase
endclass : spi_random_test

`endif // SPI_TEST_SV
