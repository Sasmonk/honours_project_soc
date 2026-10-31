// =============================================================================
// Sequence Lib : spi_seq_lib.sv
// =============================================================================
`ifndef SPI_SEQ_LIB_SV
`define SPI_SEQ_LIB_SV

class spi_base_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_base_seq)
  function new(string name = "spi_base_seq"); super.new(name); endfunction

  virtual task body();
    repeat (10) begin
      req = spi_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal("SPI_SEQ", "Randomization failed!")
      finish_item(req);
    end
  endtask : body
endclass : spi_base_seq

`endif // SPI_SEQ_LIB_SV
