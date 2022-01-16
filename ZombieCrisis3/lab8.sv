/*
 * ECE 385 Final Project: BOXHEAD:2 Player    
 *
 * "Copyright (c) 2021 by Jiazhen Xu."
 * 
 * No one has permission to copy, modify this software and its documentation for
 * any purpose without handwritten agreement. This software can but only can be 
 * distributed for academic purposes. The above copyright notice and the
 * following two paragraphs must appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE AUTHOR OR ZHEJIANG UNIVERSITY BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE AUTHOR AND/OR
 * ZHEJIANG UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE AUTHOR AND ZHEJIANG UNIVERSITY SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS
 * IS" BASIS, AND NEITHER THE AUTHOR NOR ZHEJIANG UNIVERSITY HAS ANY OBLIGATION
 * TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS OR MODIFICATIONS."
 * 
 * Author:          Jiazhen Xu, Student of ZJU-UIUC Institute 
 * Creation Date:   2021-12-15
 * Filename:        lab8.sv
 * History:
 *       Given by Instructors for lab8  
 *       modified  by Jiazhen Xu and finished on 2022-01-04
 */

module lab8( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
             // VGA Interface
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt
             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,     //SDRAM Clock
             // SRAM Interface
             output logic        SRAM_CE_N,
                                 SRAM_UB_N,
                                 SRAM_LB_N,
                                 SRAM_OE_N,
                                 SRAM_WE_N,
             output logic [19:0] SRAM_ADDR,
             inout wire   [15:0] SRAM_DQ,

             // P/S 2 Interface
             input logic PS2_KBCLK,
                         PS2_KBDAT
);
    
    logic Reset_h, Clk;	
    //needless
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;
    //keyboard signals
    logic [7:0] keycode;
    logic [7:0] keycode_1;
    logic press;    
    //Read data from SRAM 
    logic SRAM_CLK, SRAM_Read;
    logic [19:0] SRAM_Addr;
    logic [15:0] Data_Read;    
    //Visulization using two Frames
    
    logic frame;
    logic FB_Write;
    logic [9:0] FB_AddrX, FB_AddrY;
    logic [9:0] DrawX, DrawY;
    logic [4:0] ColorId, ColorId_Out, ColorId_Out_0, ColorId_Out_1;
    logic Ready;
    assign Ready = Ready_Player[0] & Ready_Player[1] && (Zombie_Ready == {26{1'b1}}) && (Devil_Ready == {10{1'b1}});
    //Interface control
    logic [1:0] CONTROL; 

    //Player control
    logic [4:0] Player_Control[2];// {1'change weapon, 1'fire, 1' is_move, 2'move_direction}; 1 for yes and 0 for no; order:上左下右
    logic Player_Id;
    logic [1:0] Player_Direction[2];
    logic [9:0] Player_X[2];
    logic [9:0] Player_Y[2];
    logic [6:0] Player_HP[2]; //128
    logic Player_State[2];
    logic Player_Hitten[2];
    logic Ready_Player[2];
    logic [1:0] Weapon[2];// 00: gun; 01: barrel; 10: block; 11: grenade.

    //Bullet Control
    logic [5:0]   Bullet_Interval[2];
    logic [6:0]   Bullet_Damage[2];
    logic [8:0]   Bullet_Counter[2];
    logic         If_Shot[2];
    logic         Bullet_Ready[2];
    logic [5:0]   Time_Counter[2];
    //Zombie control
    logic        Generate[2];
    logic [25:0] Initialization;
    logic [25:0] Zombie_Exist;
    logic [1:0] Zombie_Direction[26];
    logic [9:0] Zombie_X[26];
    logic [9:0] Zombie_Y[26];
    logic [6:0] Zombie_HP[26];
    logic [1:0] Zombie_State[26];
    logic [25:0] Zombie_Ready;
    logic       Zombie_Hitten[26];
    //Devil control
    logic [9:0] Initialization_Devil;
    logic [9:0] Devil_Exist;
    logic [1:0] Devil_Direction[10];
    logic [9:0] Devil_X[10];
    logic [9:0] Devil_Y[10];
    logic [6:0] Devil_HP[10];
    logic [1:0] Devil_State[10];
    logic [9:0] Devil_Ready;
    logic       Devil_Hitten[10];
    logic       Die[10];
    //RedBox Control
    logic [9:0] RedBox_Exist;
    logic [9:0] RedBox_X[10];
    logic [9:0] RedBox_Y[10];
    logic [9:0] Replenish;
    //Barrel control
    logic       Generate_Barrel[2];
    logic [2:0] Initialization_Barrel;
    logic [2:0] Barrel_Exist;
    logic [6:0] Barrel_HP[3];
    logic [9:0] Barrel_X[3];
    logic [9:0] Barrel_Y[3];
    logic [6:0] Barrel_Damage;
    logic [9:0] Damage_Range;
    logic [2:0]  Boom;

    //Block control
    //Grenade control
    //Fireball control


    //Control the process of the game
    logic Start,Start_in;
    logic [2:0] Level;
    initial begin
        Start = 1'b0;
    end

    always_ff @( posedge Clk ) begin 
            Start <= Start_in;
    end

    always_comb begin 
        Start_in = Start;

        if(Start == 1'b1)
        begin   
            if(CONTROL[1] == 1'b1)
                Start_in = 1'b0;
            else if(Over) begin
                Start_in = 1'b0;
            end
        end
        else begin
            if(CONTROL[0] == 1'b1)
                Start_in = 1'b1;
        end
    end

    logic Over;
    TimeFlow TimeFlow(.Clk, .Reset(Reset_h), .frame_clk(VGA_VS), .Start,  .Level, 
                    .Zombie_Exist, .Devil_Exist, .Player_HP, .Generate, .Over);

    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    

    // Use PLL to generate the 25MHZ VGA_CLK.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
    // Output VGA control signals
    VGA_controller vga_controller_instance(.Clk, .Reset(Reset_h), .VGA_HS, .VGA_VS, .VGA_CLK, .VGA_BLANK_N,
                                .VGA_SYNC_N, .DrawX, .DrawY);

    // Use PLL to generate the 26MHZ SRAM_CLK to fully use 10ns latency
    sram_clk sram_clk_instance(.inclk0(Clk), .c0(SRAM_CLK));
    // Output SRAM control signals. Read_only here
    SRAM_controller tristate(.*, .Clk(SRAM_CLK), .Reset(Reset_h), .Read(SRAM_Read), .Write(1'b0), .Data_Write(16'h0000));
    
    // P/S 2 Keyboard signals
    keyboard keyboard_instance(.Clk(Clk),.psClk(PS2_KBCLK),.psData(PS2_KBDAT),.reset(Reset_h),.keyCode(keycode),.press(press));
    key_controller key_controller_instance(.Clk, .Reset(Reset_h), .keycode(keycode), .press(press), 
                                            .player_0(Player_Control[0]) ,.player_1(Player_Control[1]), .CONTROL(CONTROL));

    // generate the frame according to position of items in SRAM
    frame_drawer frame_drawer_instance(.Clk, .Reset(Reset_h), .frame_clk(VGA_VS), .Start, .Ready,
                                .Player_Direction(Player_Direction), .Player_Control(Player_Control), .Player_X(Player_X), 
                                .Player_Y(Player_Y), .Player_State(Player_State), .Player_HP(Player_HP), .Bullet_Counter, .Weapon, .If_Shot,
                                .Zombie_Exist, .Zombie_X, .Zombie_Y, .Zombie_Direction, .Zombie_State, .Zombie_Hitten, 
                                .Devil_Exist, .Devil_X, .Devil_Y, .Devil_Direction, .Devil_State, .Devil_Hitten, 
                                .RedBox_Exist, .RedBox_X, .RedBox_Y,
                                .Barrel_Exist, .Barrel_X, .Barrel_Y, .Boom,
                                .Data_Read, .SRAM_Read, .SRAM_Addr, 
                                .frame, .FB_Write, .FB_AddrX, .FB_AddrY, .ColorId);
    
    frame_buffer frame_0(.Clk, .WE(FB_Write && frame), .Reset(Reset_h),
                        .Read_AddrX(DrawX), .Read_AddrY(DrawY),
                        .Write_AddrX(FB_AddrX), .Write_AddrY(FB_AddrY),
                        .ColorId_In(ColorId), .ColorId_Out(ColorId_Out_0));

    frame_buffer frame_1(.Clk, .WE(FB_Write && ~frame), .Reset(Reset_h),
                        .Read_AddrX(DrawX), .Read_AddrY(DrawY),
                        .Write_AddrX(FB_AddrX), .Write_AddrY(FB_AddrY),
                        .ColorId_In(ColorId), .ColorId_Out(ColorId_Out_1));

    assign ColorId_Out = frame ? ColorId_Out_1 : ColorId_Out_0;
    palette palette_instance(.ColorId(ColorId_Out), .VGA_R, .VGA_G, .VGA_B);
    
    // Player logic
    player player_0(.Clk, .Reset(Reset_h), .frame_clk(VGA_VS), .Start, .Player_Control(Player_Control), 
        .Player_Direction_I(Player_Direction), .Player_X_I(Player_X), .Player_Y_I(Player_Y), .Rand_num,
        .Player_State_I(Player_State), .Player_HP_I(Player_HP), .Weapon_I(Weapon), .Ready_I(Ready_Player), 
        .Bullet_Damage, .Bullet_Ready, .Bullet_Counter, .Time_Counter, .If_Shot,
        .Zombie_X, .Zombie_Y, .Zombie_Exist, .Devil_X, .Devil_Y, .Devil_Exist, 
        .Replenish(Replenish[0]|Replenish[1]|Replenish[2]|Replenish[3]|Replenish[4]|Replenish[5]|Replenish[6]|Replenish[7]|Replenish[8]|Replenish[9]), .Die,
        .Player_Direction(Player_Direction), .Player_X(Player_X), .Player_Y(Player_Y), .Generate_Barrel,
        .Player_State(Player_State), .Player_HP(Player_HP), .Player_Hitten(Player_Hitten), .Weapon(Weapon), .Ready(Ready_Player));
    
    //Bullet logic
    bullet bullet(.Clk, .Reset(Reset_h), .frame_clk(VGA_VS), .Start, .Die,
                    .Player_Control, .Player_HP, .Weapon, .Player_X, .Player_Y, .RedBox_X, .RedBox_Y, .RedBox_Exist, 
                    .Replenish(Replenish[0]|Replenish[1]|Replenish[2]|Replenish[3]|Replenish[4]|Replenish[5]|Replenish[6]|Replenish[7]|Replenish[8]|Replenish[9]),
                    .Ready(Bullet_Ready), .Time_Counter, .Bullet_Interval(Bullet_Interval), .Bullet_Damage(Bullet_Damage), .Bullet_Counter(Bullet_Counter), .If_Shot(If_Shot));
    
    //Barrel logic
    Barrel_Generator  Barrel_Generator(.Clk, .Generate(Generate_Barrel[0]|Generate_Barrel[1]), .Barrel_Exist, .Initialization_Barrel);

    barrel barrel(.Clk,.Reset(Reset_h), .Start, .frame_clk(VGA_VS),.Player_Control,.Player_HP, .Weapon, .If_Shot, 
                .Player_X, .Player_Y, .Player_Direction, .Bullet_Damage, .Initialization_Barrel, .Rand(Rand_num[0]),
                .Zombie_X, .Zombie_Y, .Zombie_Exist,
                .Barrel_Exist, .Barrel_HP, .Barrel_X, .Barrel_Y, .Barrel_Damage, .Damage_Range, .Boom);

    //Zombie logic
    Zombie_Generator Zombie_Generator(.Clk, .Generate(Generate[0]), .Zombie_Exist, .Initialization_out(Initialization));

    zombie zombie(.Clk, .Reset(Reset_h),  .frame_clk(VGA_VS), .Start, .Rand_num, .Initialization, .Zombie_Exist, .Zombie_Direction, .Zombie_Hitten,
                    .Zombie_X, .Zombie_Y, .Zombie_HP, .Zombie_State, .Ready(Zombie_Ready),
                    .Player_X, .Player_Y, .Player_Direction, .If_Shot,  .Player_HP,
                    .Boom, .Barrel_X, .Barrel_Y, .Barrel_Damage, .Damage_Range, .Barrel_Exist,
                    .Bullet_Damage, .Bullet_Ready, .Bullet_Counter, .Time_Counter
                    // .Barrel_Exist, .Barrel_HP, .Barrel_X, .Barrel_Y, .Barrel_Damage, .Damage_Range, .Boom
                    );
    //Devil logic 
    Devil_Generator Devil_Generator(.Clk, .Generate(Generate[1]), .Devil_Exist, .Initialization_Devil);

    Devil Devil(.Clk, .Reset(Reset_h),  .frame_clk(VGA_VS), .Start, .Initialization_Devil, .Devil_Exist, .Devil_Direction, .Devil_Hitten,
            .Devil_X, .Devil_Y, .Devil_HP, .Devil_State, .Ready(Devil_Ready), .Die,
            .Player_X, .Player_Y, .Player_Direction, .If_Shot,  .Player_HP,
            .Bullet_Damage, .Bullet_Ready, .Bullet_Counter, .Time_Counter
            );

    //Redbox logic 
    RedBox RedBox(.Clk, .frame_clk(VGA_VS), .Start, .RedBox_Exist, .RedBox_X, .RedBox_Y, .Replenish, .Die, .Devil_X, .Devil_Y, .Player_Y, .Player_X);
    
    //Random number Generator
    logic [7:0] Rand_num;
    RANGEN RANGEN(.Clk, .Start, .Rand_num);
    
    // Display keycode on hex display
    // HexDriver hex_inst_0 (keycode[3:0], HEX0);
    //  HexDriver hex_inst_0 (, HEX0);
    // HexDriver hex_inst_2 (, HEX2);
    HexDriver hex_inst_3 ({1'b0, Level}, HEX3);
    HexDriver hex_inst_4 (Start, HEX4);
    // HexDriver hex_inst_5 (Rand_num[7:4], HEX5);
    // HexDriver hex_inst_6 (, HEX6);
    // HexDriver hex_inst_7 (, HEX7);

endmodule
 