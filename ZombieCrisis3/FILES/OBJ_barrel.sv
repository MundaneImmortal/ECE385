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
 * Filename:        OBJ_barrel.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module barrel(
    input logic Clk,Reset,
    input logic frame_clk,
	 input logic Start,
    
    //Interaction
    //Player Information 
    input logic [4:0] Player_Control[2],
    input logic [6:0] Player_HP[2],
    input logic [1:0] Weapon[2],
    input logic If_Shot[2],  
    input logic [9:0] Player_X[2],
    input logic [9:0] Player_Y[2],
    input logic [1:0] Player_Direction[2],
    input logic [6:0] Bullet_Damage[2],
    input logic     Rand,
    //Zombie Information 
    input logic [9:0] Zombie_X[26],
    input logic [9:0] Zombie_Y[26],
    input logic [25:0] Zombie_Exist,
    //Barrel Signal 
    input logic [2:0]Initialization_Barrel,
    output logic [2:0] Barrel_Exist,
    output logic [6:0] Barrel_HP[3],
    output logic [9:0] Barrel_X[3],
    output logic [9:0] Barrel_Y[3],
    output logic [6:0] Barrel_Damage,
    output logic [9:0] Damage_Range,
    output logic [2:0]  Boom
    
);

    logic [2:0] Barrel_Exist_in;
    logic [6:0] Barrel_HP_in[3];
    logic [9:0] Barrel_X_in[3];
    logic [9:0] Barrel_Y_in[3];
    logic [10:0] Barrel_X_Extention[3];
    logic [10:0] Barrel_Y_Extension[3];
    logic [2:0] Boom_in;

    assign Barrel_Damage = 7'd32;
    assign Damage_Range = 10'd64;
	 
	parameter [9:0] Range = 10'd160;
    
    //Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end 

    enum logic [1:0] {
        Judge,
        Idle1,
        Idle2
    }State[3], Next_State[3];

    genvar Id;
    generate
    for(Id=0;Id<3;Id=Id+1)
    begin:xjz

        always_ff @( posedge Clk ) begin 
            if(~Start)
            begin
                Barrel_X[Id] <= 10'd0;
                Barrel_Y[Id] <= 10'd0;
                Barrel_HP[Id] <= 10'd0;
                Barrel_Exist[Id] <= 10'd0;
                Boom[Id] <= 1'b0;
                State[Id] <= Idle1;
            end
            else
            begin
                if(Barrel_Exist[Id] == 1'b0)
                begin
                    State[Id] <= Idle1;
                    if(Initialization_Barrel[Id]==1)
                    begin
                        if(Player_HP[0] == 7'b0)
                        begin
                            Barrel_X[Id] <= Player_X[1];
                            Barrel_Y[Id] <= Player_Y[1];
                        end
                        else if(Player_HP[1] == 7'b0)
                        begin
                            Barrel_X[Id] <= Player_X[0];
                            Barrel_Y[Id] <= Player_Y[0];
                        end
                        else begin
                            Barrel_X[Id] <= Player_X[Rand];
                            Barrel_Y[Id] <= Player_Y[Rand];
                        end
                        Barrel_HP[Id] <= 7'd127;   
                        Barrel_Exist[Id] <= 1'b1;
                        Boom[Id] <= Boom_in[Id];
                    end
                    else
                    begin
                        Barrel_X[Id] <= 10'd0;
                        Barrel_Y[Id] <= 10'd0;
                        Barrel_HP[Id] <= 10'd0;
                        Barrel_Exist[Id] <= Barrel_Exist_in[Id];
                        Boom[Id] <= 1'b0;
                    end  
                end
                else//Normal update
                begin
                    Barrel_X[Id] <= Barrel_X_in[Id];
                    Barrel_Y[Id] <= Barrel_Y_in[Id];
                    Barrel_HP[Id] <= Barrel_HP_in[Id];
                    Barrel_Exist[Id] <= Barrel_Exist_in[Id];  
                    State[Id] <= Next_State[Id];  
                    Boom[Id] <= Boom_in[Id];    
                end
            end
        end
        
        always_comb begin 
            Barrel_X_in[Id] = Barrel_X[Id];
            Barrel_Y_in[Id] = Barrel_Y[Id];
            Barrel_HP_in[Id] = Barrel_HP[Id];
            Barrel_Exist_in[Id] = Barrel_Exist[Id];
            Boom_in[Id] = Boom[Id];
            Next_State[Id] = State[Id];

            case(State[Id])
                Judge:
                begin
                    Next_State[Id] = Idle1;
                    if(Barrel_Exist[Id] == 1'b1)
                    begin
                        //Update Existence
                        if(Barrel_HP_in[Id] == 7'b0)
                        begin
                            Barrel_Exist_in[Id] = 1'b0;
                            Boom_in[Id] = 1'b0;
                        end
                        //Damage Detection
                        //Gunshot
        //                if( ((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b01
        //                    && (Barrel_X[Id]<Player_X[0] && Barrel_X[Id]+Range > Player_X[0])
        //                    && (Barrel_Y[Id]+10'd10 > Player_Y[0]+10'd16 && Barrel_Y[Id]<Player_Y[0]+10'd16))
        //                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b01
        //                    && (Barrel_X[Id]<Player_X[1] && Barrel_X[Id]+Range > Player_X[1])
        //                    && (Barrel_Y[Id]+10'd10 > Player_Y[1]+10'd16 && Barrel_Y[Id]<Player_Y[1]+10'd16)))
        //                    ||
        //                    ((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b11
        //                    && (Barrel_X[Id]>Player_X[0] && Barrel_X[Id]< Player_X[0]+Range)
        //                    && (Barrel_Y[Id]+10'd10 > Player_Y[0]+10'd16 && Barrel_Y[Id]<Player_Y[0]+10'd16))
        //                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b11
        //                    && (Barrel_X[Id]>Player_X[1] && Barrel_X[Id]< Player_X[1]+Range)
        //                    && (Barrel_Y[Id]+10'd10 > Player_Y[1]+10'd16 && Barrel_Y[Id]<Player_Y[1]+10'd16)))
        //                    ||
        //                    ((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b10
        //                    &&(Barrel_Y[Id]>Player_Y[0] && Barrel_Y[Id]< Player_Y[0]+Range)
        //                    &&(Barrel_X[Id]+10'd24 > Player_X[0]+10'd8 && Barrel_X[Id]<Player_X[0]+10'd8))
        //                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b10
        //                    &&(Barrel_Y[Id]>Player_Y[1] && Barrel_Y[Id]< Player_Y[1]+Range)
        //                    &&(Barrel_X[Id]+10'd24 > Player_X[1]+10'd8 && Barrel_X[Id]<Player_X[1]+10'd8)))
        //                    ||
        //                    ((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b00
        //                    &&(Barrel_Y[Id]<Player_Y[0] && Barrel_Y[Id]+Range > Player_Y[0])
        //                    &&(Barrel_X[Id]+10'd24 > Player_X[0]+10'd8 && Barrel_X[Id]<Player_X[0]+10'd8))
        //                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b00
        //                    &&(Barrel_Y[Id]<Player_Y[1] && Barrel_Y[Id]+Range > Player_Y[1])
        //                    &&(Barrel_X[Id]+10'd24 > Player_X[1]+10'd24 && Barrel_X[Id]<Player_X[1]+10'd24))))
        //                begin//To Left
        //                    if(Barrel_HP[Id] > Bullet_Damage[0])begin
        //                        Barrel_HP_in[Id] = Barrel_HP[Id] - Bullet_Damage[0];
        //                    end
        //                    else begin
        //                        Barrel_HP_in[Id] = 7'b0;
        //                        if(Barrel_HP[Id] > 7'd0)
        //                            Boom_in[Id] = 1'b1;
        //                    end
        //                end
                        //Zombie
                        if(Zombie_Exist != 26'b0)
                        begin
                            for(int i = 0; i<26; i = i+1)
                            begin
                                int DistX[26];
                                int DistY[26];
                                DistX[i] = Barrel_X[Id] - Zombie_X[i];
                                DistY[i] = Barrel_Y[Id] - Zombie_Y[i];

                                if( DistX[i]*DistX[i] + DistY[i]*DistY[i] <= 32*32)
                                begin
                                    if(Barrel_HP[Id] > 7'd64)begin
                                    Barrel_HP_in[Id] = Barrel_HP[Id] - 7'd64;
                                    end
                                    else begin
                                        Barrel_HP_in[Id] = 7'b0;
                                        if(Barrel_HP[Id] > 7'd0)
                                            Boom_in[Id] = 1'b1;
                                    end
                                end
                            end
                        end
                        else begin//other barrel
        //                    for(int i = 0; i<5; i = i+1)
        //                    begin
        //                        int DistX[5];
        //                        int DistY[5];
        //                        DistX[i] = Barrel_X[Id] - Barrel_X[i];
        //                        DistY[i] = Barrel_Y[Id] - Barrel_Y[i];
        //
        //                        if(i!=Id && Boom[Id] == 1'b1 &&  DistX[i]*DistX[i] + DistY[i]*DistY[i] <= Damage_Range)
        //                        begin
        //                            if(Barrel_HP[Id] > Barrel_Damage)begin
        //                            Barrel_HP_in[Id] = Barrel_HP[Id] - Barrel_Damage;
        //                            end
        //                            else begin
        //                                Barrel_HP_in[Id] = 7'b0;
        //                                if(Barrel_HP[Id] > 7'd0)
        //                                    Boom_in[Id] = 1'b1;
        //                            end
        //                        end
        //                    end
                        end
                    end
                    else begin
                        Barrel_HP_in[Id] = 7'b0;
                        Barrel_X_in[Id] = 10'd0;
                        Barrel_Y_in[Id] = 10'd0;
                    end
                end

                Idle1:
                begin
                    if (frame_clk_rising_edge)
                        Next_State[Id] = Idle2;
                end

                Idle2:
                begin
                    Boom_in[Id] = 1'b0;
                    Next_State[Id] = Judge;
                end

			endcase
        end
    end
    endgenerate

endmodule


module Barrel_Generator(
	 input logic Clk,
    input logic Generate,
    input logic [2:0] Barrel_Exist,
    output logic [2:0] Initialization_Barrel
);
	 logic [2:0] Initialization;
	 
    always_ff @( posedge Clk) begin
        Initialization_Barrel <= Initialization;
    end

    always_comb begin 

        Initialization = 10'b0;
        if( Generate == 1'b1 )begin
            if(Barrel_Exist[0]==1'b0)begin
                Initialization[0]=1'b1;
            end
            else begin
                if(Barrel_Exist[1]==1'b0)begin
                    Initialization[1]=1'b1;
                end
                else begin
                    if(Barrel_Exist[2]==1'b0)begin
                        Initialization[2]=1'b1;
                    end
                    else begin

                    end
                end
            end
        end
    end
endmodule