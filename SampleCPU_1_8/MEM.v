`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus

    // output wire [31:0] rf_wdata  //+
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (flush) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [65:0] hilo_bus;//1.8
    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;

    wire [4:0] mem_op;

    assign {
        mem_op,        //80:76
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;

    wire inst_lw, inst_lh;
    assign {inst_lw, inst_lh} = mem_op;

    //Load Data
    reg [31:0] mem_result_r;
    always @ (*) begin
        case(1'b1)
            inst_lw:
            begin
                mem_result_r <= data_sram_rdata;
            end
            default:
            begin
                mem_result_r <= 32'b0;
            end
            inst_lh:
            begin
                case(ex_result[1:0])
                    2'b00:
                    begin
                        mem_result_r <= {{16{data_sram_rdata[15]}},data_sram_rdata[15:0]};
                    end
                    
                    2'b10:
                    begin
                        mem_result_r <= {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]};
                    end
                    default:
                    begin
                        mem_result_r <= 32'b0;
                    end
                endcase
            end
        endcase
    end

    assign mem_result = mem_result_r;

    assign rf_wdata = sel_rf_res ? mem_result : ex_result;

    assign mem_to_wb_bus = {
        hilo_bus,        // 135:70  //1.8
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };

    // id u_id(
    //     rf_we,
    //     rf_waddr,
    //     rf_wdata
    // )




endmodule