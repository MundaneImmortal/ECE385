
module SRAM_controller(
    // Data stream
    input logic Clk, Reset, // 100MHZ Clk
    input logic Read, Write,
    input logic [19:0] SRAM_Addr,
    input logic [15:0] Data_Write,
    output logic [15:0] Data_Read,
    // SRAM signals
    output logic SRAM_CE_N,
                SRAM_UB_N,
                SRAM_LB_N,
                SRAM_OE_N,
                SRAM_WE_N,
    output logic [19:0] SRAM_ADDR,
    // data
    inout wire [15:0] SRAM_DQ
);
    // Registers are needed between synchronized circuit and asynchronized SRAM 
    logic [15:0] Data_Write_buffer, Data_Read_buffer;

    always_ff @(posedge Clk)
    begin
        // Always Read data from the bus
        Data_Read_buffer <= SRAM_DQ;
        // Always updated with the data from Mem2IO which will be written to the bus
        Data_Write_buffer <= Data_Write;
    end

    always_comb
    begin
        SRAM_OE_N = 1'b1;
        SRAM_WE_N = 1'b1;
        if(Read && ~Write)
            SRAM_OE_N = 1'b0;
        if(~Read && Write)
            SRAM_WE_N = 1'b0;
    end
    
    // These should always be active
    assign SRAM_CE_N = 1'b0;
    assign SRAM_UB_N = 1'b0;
    assign SRAM_LB_N = 1'b0;
    assign SRAM_ADDR = SRAM_Addr;
    
    // Drive (Write to) Data bus only when tristate_output_enable is active.
    assign SRAM_DQ = (~Read && Write) ? Data_Write_buffer : {16{1'bz}};

    assign Data_Read = Data_Read_buffer;
    
endmodule
