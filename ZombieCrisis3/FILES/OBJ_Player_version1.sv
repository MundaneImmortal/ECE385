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
 * Filename:        OBJ_Player.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module player(
    input logic         Clk, Reset,
    input logic         frame_clk,
	input logic			Start,
    input logic [7:0] Rand_num,
	 
    input logic [4:0]   Player_Control[2],

    input logic [1:0]  Player_Direction_I[2], // 0: up, 1: left, 2: down, 3: right
    input logic [9:0]  Player_X_I[2],
                        Player_Y_I[2],
    input logic        Player_State_I[2], // movement state
    input logic [6:0]  Player_HP_I[2],
    input logic [1:0]  Weapon_I[2],
    input logic [1:0]  Ready_I[2],
    //Interaction
    //Bullet
    input logic [6:0]  Bullet_Damage[2],
    input logic         If_Shot[2],
    input logic         Bullet_Ready[2],
    input logic [8:0]   Bullet_Counter[2],
    input logic [5:0]   Time_Counter[2],
    //Zombie
    input logic [25:0]  Zombie_Exist,
    input logic [9:0]   Zombie_X[26],
    input logic [9:0]   Zombie_Y[26],
    //Devil
    input logic [9:0]   Devil_Exist,
    input logic [9:0]   Devil_X[10],
    input logic [9:0]   Devil_Y[10],   
    input logic         Die[10], 
    //RedBox
    input logic         Replenish,
    // Output property of a Player
    output logic [1:0]  Player_Direction[2], // 0: up, 1: left, 2: down, 3: right
    output logic [9:0]  Player_X[2],
                        Player_Y[2],
    output logic        Player_State[2], // movement state
    output logic [6:0]  Player_HP[2],
    output logic        Player_Hitten[2], // 1 for hitten ; 0 for not
    output logic [1:0]  Weapon[2],
    output logic        Generate_Barrel[2],

    output logic        Ready[2] // ready = 1, when all judgement completed

);
    parameter [9:0] Player_X_Min = 10'd0;       // Leftmost point on the X axis
    parameter [9:0] Player_X_Max = 10'd640;     // Rightmost point on the X axis
    parameter [9:0] Player_Y_Min = 10'd0;       // Topmost point on the Y axis
    parameter [9:0] Player_Y_Max = 10'd480;     // Bottommost point on the Y axis
    parameter [9:0] Player_X_Step = 10'd2;      // Step size on the X axis
    parameter [9:0] Player_Y_Step = 10'd2;      // Step size on the Y axis
    parameter [9:0] Player_X_Hitten_Step = 10'd8;
    parameter [9:0] Player_Y_Hitten_Step = 10'd8;
    parameter [9:0] Player_Size = 10'd32;       // Player size
    parameter [6:0] Zombie_Damage = 7'd1;

    parameter [9:0] Range = 10'd160;  //Attack range
    parameter [5:0] Base_Interval = 6'd5;


    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end    
	
    logic [1:0] Hitten_Direction[2];

	logic Ready_in[2];
    logic [1:0] Player_Direction_in[2];
    logic [9:0] Player_X_in[2];
	logic [9:0] Player_Y_in[2];
    logic Player_State_in[2];
    logic [6:0] Player_HP_in[2];
    logic [1:0] Weapon_in[2];
    logic 	Player_Hitten_in[2];
    logic [1:0] Hitten_Direction_in[2];
    logic [9:0] X_Motion[2], Y_Motion[2];
    logic Turn_Direction[2];

    logic Barrel_Counter[2];
    logic Barrel_Counter_in[2];

    logic [6:0] Damage[2];
    
    enum logic [1:0] {
        Hitten_Judgement,
        Feedback,
        Idle1,
        Idle2
    }State[2], Next_State[2];

	//Distance from Zombies
    int DistX_1[26]; 
	int DistX_2[26];
    int DistY_1[26];
	int DistY_2[26]; 
    genvar j;
    generate
    for(j=0;j<=25;j=j+1)
    begin:XJZ
    assign DistX_1[j] = Zombie_X[j] - Player_X[0];
    assign DistX_2[j] = Zombie_X[j] - Player_X[1];
    assign DistY_1[j] = Zombie_Y[j] - Player_Y[0];
    assign DistY_2[j] = Zombie_Y[j] - Player_Y[1];
    end
    endgenerate

    //Distance from Devils
    int DistX_Devil_1[10]; 
	int DistX_Devil_2[10];
    int DistY_Devil_1[10];
	int DistY_Devil_2[10]; 
    genvar k;
    generate
    for(k=0;k<=9;k=k+1)
    begin:Xjz
    assign DistX_Devil_1[k] = Devil_X[k] - Player_X[0];
    assign DistX_Devil_2[k] = Devil_X[k] - Player_X[1];
    assign DistY_Devil_1[k] = Devil_Y[k] - Player_Y[0];
    assign DistY_Devil_2[k] = Devil_Y[k] - Player_Y[1];
    end
    endgenerate

	genvar Id; 
    generate
	for(Id=0;Id<2;Id=Id+1)
	begin:xjz
	    
    assign Damage[Id] = Bullet_Damage[Id];

    always_ff @(posedge Clk) begin
        if(~Start)
        begin
            Player_Direction[Id] <= 2'b00;
            Ready[Id] <= 1'b0;
            Player_HP[Id] <= 7'd127;
            Player_State[Id] <= 1'b0;
            Weapon[Id] <= 2'b00;
            State[Id] <= Idle1;
            Player_Hitten[Id] <= 1'b0;
            Barrel_Counter[Id] <=10'd0;
            //Collision_Select[Id] <= 1'b0;
            case(Id)
                 0:
                begin
                    Player_X[Id] <= 10'd200;
                    Player_Y[Id] <= 10'd198;
                end
                1:
                begin
                    Player_X[Id] <= 10'd418;
                    Player_Y[Id] <= 10'd198;
                end
				endcase
        end
        else begin
            Ready[Id] <= Ready_in[Id];
            Player_X[Id] <= Player_X_in[Id];
            Player_Y[Id] <= Player_Y_in[Id];
            Player_Direction[Id] <= Player_Direction_in[Id];
            Player_HP[Id] <= Player_HP_in[Id];
            Player_State[Id] <= Player_State_in[Id];
            Player_Hitten[Id] <= Player_Hitten_in[Id];
            Hitten_Direction[Id] <= Hitten_Direction_in[Id];
            Weapon[Id] <= Weapon_in[Id];
            State[Id] <= Next_State[Id];
            Barrel_Counter[Id] <= Barrel_Counter_in[Id];
        end
    end

    always_comb begin
        Ready_in[Id] = Ready[Id];
        Player_X_in[Id] = Player_X_I[Id];
        Player_Y_in[Id] = Player_Y_I[Id];
        Player_Direction_in[Id] = Player_Direction_I[Id];
        Player_HP_in[Id] = Player_HP_I[Id];
        Player_State_in[Id] = Player_State_I[Id];
        Weapon_in[Id] = Weapon_I[Id];
        X_Motion[Id] = 10'b0;
        Y_Motion[Id] = 10'b0;
        Player_Hitten_in[Id] = Player_Hitten[Id];
        Hitten_Direction_in[Id] = Hitten_Direction[Id];
        Barrel_Counter_in[Id] = Barrel_Counter[Id];
        Turn_Direction[Id] = 1'b0;
        Generate_Barrel[Id] = 1'b0;

        Next_State[Id] = State[Id];


        case(State[Id])
            Hitten_Judgement:
            begin
                Next_State[Id] = Feedback;
                //"Friends' Shot" detection
                case(Id)
                    0: begin
                            if( If_Shot[1]
                             && (Player_X[1]+10'd10 > Player_X[0]) && (Player_X[1] < Player_X[0]+10'd10) && 
                                    (Player_Y[1]+Range > Player_Y[0]) && (Player_Y[1] < Player_Y[0])  &&
                                    (Player_Direction[1] == 2'b10) ) //1上0下
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = 2'b00;
                                        if(Player_HP[0] > Damage[1])begin
                                            Player_HP_in[0] = Player_HP[0] - Damage[1];
                                            
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                            else if ( If_Shot[1]
                             && (Player_X[1]+10'd10 > Player_X[0]) && (Player_X[1] < Player_X[0]+10'd10) && 
                                    (Player_Y[1] < Player_Y[0]+Range) && (Player_Y[1] > Player_Y[0]) &&
                                    (Player_Direction[1] == 2'b00) ) //1下0上
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = 2'b10;
                                        if(Player_HP[0] > Damage[1])begin
                                            Player_HP_in[0] = Player_HP[0] - Damage[1];    
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                            else if ( If_Shot[1]
                             && (Player_Y[1]+10'd16 > Player_Y[0]) && (Player_Y[1] < Player_Y[0]+10'd16) && 
                                    (Player_X[1] < Player_X[0]+Range) && (Player_X[1] > Player_X[0]) &&
                                    (Player_Direction[1] == 2'b01) ) //1右0左
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = 2'b11;
                                        if(Player_HP[0] > Damage[1])begin
                                            Player_HP_in[0] = Player_HP[0] - Damage[1];
                                            
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                            else if (If_Shot[1]
                             && (Player_Y[1]+10'd16 > Player_Y[0]) && (Player_Y[1] < Player_Y[0]+10'd16) && 
                                    (Player_X[1]+Range > Player_X[0]) && (Player_X[1] < Player_X[0]) &&
                                    (Player_Direction[1] == 2'b11)) //1左0右
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = 2'b01;
                                        if(Player_HP[0] > Damage[1])begin
                                            Player_HP_in[0] = Player_HP[0] - Damage[1];
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                            else  
                            begin//Zombie & Devil Attack Detection
                                for(int i=0 ; i<26 ; i=i+1)
                                begin
                                    if ( DistX_1[i]*DistX_1[i] + DistY_1[i]*DistY_1[i] <= 24*24  && Zombie_Exist[i] == 1'b1)
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = Rand_num[1:0];
                                        if(Player_HP[0] > Zombie_Damage)begin
                                            Player_HP_in[0] = Player_HP[0] - Zombie_Damage;
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                                end
                                for(int i=0 ; i<10 ; i=i+1)
                                begin
                                    if ( DistX_Devil_1[i]*DistX_Devil_1[i] + DistY_Devil_1[i]*DistY_Devil_1[i] <= 24*24  && Devil_Exist[i] == 1'b1)
                                    begin
                                        Player_Hitten_in[0] = 1'b1; 
                                        Hitten_Direction_in[0] = Rand_num[1:0];
                                        if(Player_HP[0] > (Zombie_Damage<<2) )begin
                                            Player_HP_in[0] = Player_HP[0] - (Zombie_Damage<<2);
                                        end
                                        else begin
                                            Player_HP_in[0] = 7'b0;
                                        end
                                    end
                                end
                            end

                    end
                    1:  begin
                        if( If_Shot[0]
                         && (Player_X[0]+10'd10 > Player_X[1]) && (Player_X[0] < Player_X[1]+10'd10) && 
                            (Player_Y[0]+Range > Player_Y[1]) && (Player_Y[0] < Player_Y[1]) &&
                            (Player_Direction[0] == 2'b10) ) //0上1下
                            begin
                                Player_Hitten_in[1] = 1'b1; 
                                Hitten_Direction_in[1] = 2'b00;
                                if(Player_HP[1] > Damage[0])begin
                                    Player_HP_in[1] = Player_HP[1] - Damage[0];
                                end
                                else begin
                                    Player_HP_in[1] = 7'b0;
                                end
                            end
                        else if ( If_Shot[0]
                         && (Player_X[0]+10'd10 > Player_X[1]) && (Player_X[0] < Player_X[1]+10'd10) && 
                            (Player_Y[0] < Player_Y[1]+Range) && (Player_Y[0] > Player_Y[1]) &&
                            (Player_Direction[0] == 2'b00) ) //0下1上
                            begin
                                Player_Hitten_in[1] = 1'b1; 
                                    Hitten_Direction_in[1] = 2'b10;
                                if(Player_HP[1] > Damage[0])begin
                                    Player_HP_in[1] = Player_HP[1] - Damage[0];                                    
                                end
                                else begin
                                    Player_HP_in[1] = 7'b0;
                                end
                            end
                        else if ( If_Shot[0]
                         && (Player_Y[0]+10'd16 > Player_Y[1]) && (Player_Y[0] < Player_Y[1]+10'd16) && 
                            (Player_X[0] < Player_X[1]+Range) && (Player_X[0] > Player_X[1]) &&
                            (Player_Direction[0] == 2'b01) ) //0右1左
                            begin
                                Player_Hitten_in[1] = 1'b1; 
                                Hitten_Direction_in[1] = 2'b11;
                                if(Player_HP[1] > Damage[0])begin
                                    Player_HP_in[1] = Player_HP[1] - Damage[0];    
                                end
                                else begin
                                    Player_HP_in[1] = 7'b0;
                                end
                            end
                        else if ( If_Shot[0]
                         && (Player_Y[0]+10'd16 > Player_Y[1]) && (Player_Y[0] < Player_Y[1]+10'd16) && 
                            (Player_X[0]+Range > Player_X[1]) && (Player_X[0] < Player_X[1]) &&
                            (Player_Direction[0] == 2'b11)) //0左1右
                            begin
                                Player_Hitten_in[1] = 1'b1; 
                                Hitten_Direction_in[1] = 2'b01;
                                if(Player_HP[1] > Damage[0])begin
                                    Player_HP_in[1] = Player_HP[1] - Damage[0];
                                end
                                else begin
                                    Player_HP_in[1] = 7'b0;
                                end
                            end
                        else  
                        begin//Zombie Attack Detection
                            for(int i=0 ; i<26 ; i=i+1)
                            begin
                                if ( DistX_2[i]*DistX_2[i] + DistY_2[i]*DistY_2[i] <= 24*24 && Zombie_Exist[i] == 1'b1)
                                begin
                                    Player_Hitten_in[1] = 1'b1; 
                                    Hitten_Direction_in[1] = Rand_num[1:0];
                                    if(Player_HP[1] > Zombie_Damage)begin
                                        Player_HP_in[1] = Player_HP[1] - Zombie_Damage;
                                    end
                                    else begin
                                        Player_HP_in[1] = 7'b0;
                                    end
                                end
                            end
                            for(int i=0 ; i<10 ; i=i+1)
                            begin
                                if ( DistX_Devil_2[i]*DistX_Devil_2[i] + DistY_Devil_2[i]*DistY_Devil_2[i] <= 24*24 && Devil_Exist[i] == 1'b1)
                                begin
                                    Player_Hitten_in[1] = 1'b1; 
                                    Hitten_Direction_in[1] = Rand_num[1:0];
                                    if(Player_HP[1] > (Zombie_Damage<<2) )begin
                                        Player_HP_in[1] = Player_HP[1] - (Zombie_Damage<<2);
                                    end
                                    else begin
                                        Player_HP_in[1] = 7'b0;
                                    end
                                end
                            end
                        end
                    end
                endcase
            end

            Feedback:
            begin
                Next_State[Id] = Idle1;
                if(Player_HP[Id] != 7'd0)
                begin
                    if(Replenish == 1'b1 || Die[0]|Die[1]|Die[2]|Die[3]|Die[4]|Die[5]|Die[6]|Die[7]|Die[8]|Die[9] == 1'b1)
                    begin
                        Player_HP_in[Id] = 7'd127;
                    end
                    //Place barrels
                    if(Player_Control[Id][3] == 1'b1 && Weapon[Id] == 2'b01 && Player_HP[Id] != 7'b0)
                    begin
                        Generate_Barrel[Id] = 1'b1;
                    end
                    //Weapon selection and movement are only available when not being hitten
                    if(Player_Hitten[Id] == 1'b0)
                    begin
                        //Weapon selection
                        if(Player_Control[Id][4] == 1'b1)
                        begin  
                            if(Weapon[Id] == 2'b01)
                                Weapon_in[Id] = 2'b00;
                            else 
                                Weapon_in[Id] = Weapon[Id] + 2'b01;
                        end
                        //Movement
                        case(Player_Control[Id][2:0])
                            3'b101: // left
                            begin
                                if(Player_Direction[Id] == 2'b01)
                                begin
                                    X_Motion[Id] = (~(Player_X_Step)+1'b1);
                                    Y_Motion[Id] = 10'd0;
                                    Player_State_in[Id] = ~Player_State[Id];
                                end
                                else begin
                                    Turn_Direction[Id] = 1'b1;
                                    Player_Direction_in[Id] = 2'b01;
                                end
                            end
                            3'b111:// right
                            begin
                                if(Player_Direction[Id] == 2'b11)
                                begin
                                    X_Motion[Id] = Player_X_Step;
                                    Y_Motion[Id] = 10'd0;
                                    Player_State_in[Id] = ~Player_State[Id];
                                end
                                else begin
                                    Turn_Direction[Id] = 1'b1;
                                    Player_Direction_in[Id] = 2'b11;
                                end
                            end
                            3'b110://down
                            begin
                                if(Player_Direction[Id] == 2'b10)
                                begin
                                    X_Motion[Id] = 10'd0;
                                    Y_Motion[Id] = Player_Y_Step;
                                    Player_State_in[Id] = ~Player_State[Id];
                                end
                                else begin
                                    Turn_Direction[Id] = 1'b1;
                                    Player_Direction_in[Id] = 2'b10;
                                end
                            end
                            3'b100://up
                            begin
                                if(Player_Direction[Id] == 2'b00)
                                begin
                                    X_Motion[Id] = 10'd0;
                                    Y_Motion[Id] = (~(Player_Y_Step) + 1'b1);
                                    Player_State_in[Id] = ~Player_State[Id];
                                end
                                else begin
                                    Turn_Direction[Id] = 1'b1;
                                    Player_Direction_in[Id] = 2'b00;
                                end
                            end
                        endcase
                    end
                    else if (Player_Hitten[Id] == 1'b1)//If being hitten, step back and change the state for animation.
                    begin
                        //change the state
                        Player_State_in[Id] = ~Player_State[Id];
                        //respond to the damage
                        case(Hitten_Direction_in[Id])
                            2'b00: //from up
                            begin
                                X_Motion[Id] = 10'd0;
                                Y_Motion[Id] = Player_Y_Hitten_Step;
                                        Player_Direction_in[Id] = 2'b00;
                            end
                            2'b01://from left
                            begin
                                X_Motion[Id] = Player_X_Hitten_Step;
                                Y_Motion[Id] = 10'd0;
                                        Player_Direction_in[Id] = 2'b01;
                            end
                            2'b10://from down
                            begin
                                X_Motion[Id] = 10'd0;
                                Y_Motion[Id] = ~(Player_Y_Hitten_Step)+1;
                                        Player_Direction_in[Id] = 2'b10;
                            end
                            2'b11://from right
                            begin
                                X_Motion[Id] = ~(Player_X_Hitten_Step)+1;
                                Y_Motion[Id] = 10'd0;
                                        Player_Direction_in[Id] = 2'b11;
                            end
                                
                        endcase
                        Player_Hitten_in[Id] = 10'b0;
                    end
                    //Move
                    Player_X_in[Id] = Player_X[Id] + X_Motion[Id];
                    Player_Y_in[Id] = Player_Y[Id] + Y_Motion[Id];
                    //Boundary check
                    if( Player_X_in[Id] + Player_Size > Player_X_Max || Player_X_in[Id] > Player_X_Max ) 
                        Player_X_in[Id] = Player_X[Id];
                    if( Player_Y_in[Id] + Player_Size > Player_Y_Max || Player_Y_in[Id] > Player_Y_Max )  
                        Player_Y_in[Id] = Player_Y[Id];
                end
                
            end
            
            Idle1:
            begin
                Ready_in[Id] = 1'b1;
                if (frame_clk_rising_edge && Ready[Id])
                    Next_State[Id] = Idle2; 
            end

            Idle2:
            begin
                Ready_in[Id] = 1'b0;
                if( Bullet_Ready[Id] == 1'b1)
                begin
                    Next_State[Id] = Hitten_Judgement; 
                end
            end
        endcase
	end

    end
	endgenerate

endmodule