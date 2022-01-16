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
 * Filename:        OBJ_Zombie.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module zombie(
    input logic Clk, Reset, 
    input logic frame_clk,
	 input logic Start,
     input logic [7:0] Rand_num,
    //zombie control
    input logic [25:0] Initialization,
    output logic [25:0] Zombie_Exist, //one-hot encoding, 1 for live and 0 for dead
 
    //zombie information
    output logic [1:0] Zombie_Direction[26],
    output logic [9:0] Zombie_X[26],
    output logic [9:0] Zombie_Y[26],
    output logic [6:0] Zombie_HP[26],
    output logic [1:0] Zombie_State[26], //walk, walk, hit, hitten
    output logic       Zombie_Hitten[26],
    output logic [25:0]      Ready,
    //interaction
    //Player
    input logic [9:0] Player_X[2],
    input logic [9:0] Player_Y[2],
    input logic [1:0] Player_Direction[2],
    input logic [6:0] Player_HP[2],
    input logic       If_Shot[2],
    //Bullet
    input logic [6:0]  Bullet_Damage[2],
    input logic         Bullet_Ready[2],
    input logic [8:0]   Bullet_Counter[2],
    input logic [5:0]   Time_Counter[2],
    //Barrel
    input logic [2:0] Barrel_Exist,
    input logic [9:0] Barrel_X[3],
    input logic [9:0] Barrel_Y[3],
    input logic [6:0] Barrel_Damage,
    input logic [9:0] Damage_Range,
    input logic [2:0] Boom

);

    parameter [9:0] Zombie_X_Min = 10'd0;
    parameter [9:0] Zombie_X_Max = 10'd640;
    parameter [9:0] Zombie_Y_Min = 10'd0;
    parameter [9:0] Zombie_Y_Max = 10'd480;
    parameter [9:0] Zombie_Step = 10'd1;
    parameter [9:0] Zombie_Hitten_Step = 10'd5;
    parameter [9:0] Zombie_Size = 10'd32;
    parameter [9:0] Range = 10'd160;

    //Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end 

    enum logic [1:0] {
        Hitten_Judgement,
        Feedback,
        Idle1,
        Idle2
    }State[26], Next_State[26];
    
    logic [9:0] Zombie_Direction_in[26];
    logic [9:0] Zombie_X_in[26];
    logic [9:0] Zombie_Y_in[26];
    logic [6:0] Zombie_HP_in[26];
    logic [1:0] Zombie_State_in[26];
    logic [25:0] Zombie_Exist_in;
    logic [9:0] X_Motion[26], Y_Motion[26];
    logic [9:0] X_Motion_in[26], Y_Motion_in[26];

    
    logic Zombie_Hitten_in[26];
    logic [1:0] Hitten_Direction[26];
    logic [1:0] Hitten_Direction_in[26];
    logic [25:0]   Ready_in;
    logic [6:0]     Hurt;
    assign Hurt = Bullet_Damage[0] << 2 ;
    
    int DistX_1[26]; 
	 int DistX_2[26];
    int DistY_1[26];
	 int DistY_2[26]; 

    int DistX[26][3];
    int DistY[26][3];

    int damage_range;
    assign damage_range = Damage_Range;

    genvar Id;
    generate
    for(Id=0;Id<=25;Id=Id+1)
    begin:xjz

    assign DistX_1[Id] = Zombie_X[Id] - Player_X[0];
    assign DistX_2[Id] = Zombie_X[Id] - Player_X[1];
    assign DistY_1[Id] = Zombie_Y[Id] - Player_Y[0];
    assign DistY_2[Id] = Zombie_Y[Id] - Player_Y[1];

    always_ff @( posedge Clk ) begin 
        if(~Start)
        begin
            Zombie_Direction[Id] <= 2'd0;
            Zombie_X[Id] <= 10'd0;
            Zombie_Y[Id] <= 10'd0;
            X_Motion[Id] <= 10'd0;
            Y_Motion[Id] <= 10'd0;
            Zombie_HP[Id] <= 10'd0;
            Zombie_State[Id] <= 10'd0;
            Zombie_Exist[Id] <= 10'd0;
            Ready[Id] <= 1'b0;
            Zombie_Hitten[Id] <= 1'b0;
            State[Id] <= Idle1;
        end
        else
        begin
            if(Zombie_Exist[Id] == 1'b0)
            begin
                if(Initialization[Id]==1)
                begin
                    if( Id%2 == 0 )
                    begin
                        Zombie_Direction[Id] <=  2'b00;
                        Zombie_Y[Id] <= 10'd448;
                    end
                    else
                    begin
                        Zombie_Direction[Id] <= 2'b10;
                        Zombie_Y[Id] <= 10'd0;
                    end
                    Zombie_X[Id] <= {2'b00, Rand_num} + 10'd160;
                    X_Motion[Id] <= 10'd0;
                    Y_Motion[Id] <= 10'd0;
                    Zombie_HP[Id] <= 7'd127;   
                    Zombie_Exist[Id] <= 1'b1;
                    Zombie_Hitten[Id] <= 1'b0; 
                    Hitten_Direction[Id] <= 2'b00;
                    State[Id] <= Idle1;
                    Ready[Id] <= 1'b1;
                end
                else
                begin
                    Zombie_Direction[Id] <= 2'd0;
                    Zombie_X[Id] <= 10'd0;
                    Zombie_Y[Id] <= 10'd0;
                    X_Motion[Id] <= 10'd0;
                    Y_Motion[Id] <= 10'd0;
                    Zombie_HP[Id] <= 10'd0;
                    Zombie_State[Id] <= 10'd0;
                    Zombie_Exist[Id] <= Zombie_Exist_in[Id];
                    State[Id] <= Idle1;
                    Ready[Id] <= 1'b1;
                end  
            end
            else//Normal update
            begin
                Zombie_Direction[Id] <= Zombie_Direction_in[Id];
                Zombie_X[Id] <= Zombie_X_in[Id];
                Zombie_Y[Id] <= Zombie_Y_in[Id];
                X_Motion[Id] <= X_Motion_in[Id];
                Y_Motion[Id] <= Y_Motion_in[Id];
                Zombie_HP[Id] <= Zombie_HP_in[Id];
                Zombie_State[Id] <= Zombie_State_in[Id];
                Zombie_Exist[Id] <= Zombie_Exist_in[Id];
                Zombie_Hitten[Id] <= Zombie_Hitten_in[Id];
                Hitten_Direction[Id] <= Hitten_Direction_in[Id];
                State[Id] <= Next_State[Id];
                Ready[Id] <= Ready_in[Id];                
            end
        end
        
    end

    always_comb begin 
        Zombie_Exist_in[Id] = Zombie_Exist[Id];
        Zombie_State_in[Id] = Zombie_State[Id];
        Zombie_HP_in[Id] = Zombie_HP[Id];
        Zombie_X_in[Id] = Zombie_X[Id];
        Zombie_Y_in[Id] = Zombie_Y[Id];
        Zombie_Direction_in[Id] = Zombie_Direction[Id];
        X_Motion_in[Id] = X_Motion[Id];
        Y_Motion_in[Id] = Y_Motion[Id];
        Zombie_Hitten_in[Id] =  Zombie_Hitten[Id];
        Hitten_Direction_in[Id] = Hitten_Direction[Id];
		Ready_in[Id] = Ready[Id];

        Next_State[Id] = State[Id];         

        if( Zombie_HP[Id] == 7'd0 )
            Zombie_Exist_in[Id] = 1'b0;

        case(State[Id])
            Hitten_Judgement:
            begin
                Next_State[Id] = Feedback;
                if( (If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b01
                    && (Zombie_X[Id]<Player_X[0] && Zombie_X[Id]+Range > Player_X[0])
                    && (Zombie_Y[Id]+10'd30 > Player_Y[0]+10'd16 && Zombie_Y[Id]<Player_Y[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b01
                    && (Zombie_X[Id]<Player_X[1] && Zombie_X[Id]+Range > Player_X[1])
                    && (Zombie_Y[Id]+10'd30 > Player_Y[1]+10'd16 && Zombie_Y[Id]<Player_Y[1]+10'd16)))
                begin//To Left
                    Zombie_Hitten_in[Id] = 1'b1;
                    if(Zombie_HP_in[Id] > Hurt)begin
                        Zombie_HP_in[Id] = Zombie_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b01;
                    end
                    else begin
                        Zombie_HP_in[Id] = 7'b0;
                    end
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b11
                    && (Zombie_X[Id]>Player_X[0] && Zombie_X[Id]< Player_X[0]+Range)
                    && (Zombie_Y[Id]+10'd30 > Player_Y[0]+10'd16 && Zombie_Y[Id]<Player_Y[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b11
                    && (Zombie_X[Id]>Player_X[1] && Zombie_X[Id]< Player_X[1]+Range)
                    && (Zombie_Y[Id]+10'd30 > Player_Y[1]+10'd16 && Zombie_Y[Id]<Player_Y[1]+10'd16)))
                begin//To Right
                    if(Zombie_HP_in[Id] > Hurt)begin
                        Zombie_HP_in[Id] = Zombie_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b11;
                    end
                    else begin
                        Zombie_HP_in[Id] = 7'b0;
                    end
                    Zombie_Hitten_in[Id] = 1'b1;
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b10
                    &&(Zombie_Y[Id]>Player_Y[0] && Zombie_Y[Id]< Player_Y[0]+Range)
                    &&(Zombie_X[Id]+10'd24 > Player_X[0]+10'd8 && Zombie_X[Id]<Player_X[0]+10'd6))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b10
                    &&(Zombie_Y[Id]>Player_Y[1] && Zombie_Y[Id]< Player_Y[1]+Range)
                    &&(Zombie_X[Id]+10'd24 > Player_X[1]+10'd8 && Zombie_X[Id]<Player_X[1]+10'd6)))
                begin//To Down
                    if(Zombie_HP_in[Id] > Hurt)begin
                        Zombie_HP_in[Id] = Zombie_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b10;
                    end
                    else begin
                        Zombie_HP_in[Id] = 7'b0;
                    end
                    Zombie_Hitten_in[Id] = 1'b1;
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b00
                    &&(Zombie_Y[Id]<Player_Y[0] && Zombie_Y[Id]+Range > Player_Y[0])
                    &&(Zombie_X[Id]+10'd16 > Player_X[0]+10'd8 && Zombie_X[Id]<Player_X[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b00
                    &&(Zombie_Y[Id]<Player_Y[1] && Zombie_Y[Id]+Range > Player_Y[1])
                    &&(Zombie_X[Id]+10'd16 > Player_X[1]+10'd8 && Zombie_X[Id]<Player_X[1]+10'd16)))
                begin//To Up
                    if(Zombie_HP_in[Id] > Hurt)begin
                        Zombie_HP_in[Id] = Zombie_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b00;
                    end
                    else begin
                        Zombie_HP_in[Id] = 7'b0;
                    end
                    Zombie_Hitten_in[Id] = 1'b1;
                end
                //priority:fire ball
                //priority:barrel
                else if(Barrel_Exist != 3'b0)
                begin 
                    for(int i =0 ; i<3; i = i+1)
                    begin
                        DistX[Id][i] = Zombie_X[Id] - Barrel_X[i];
                        DistY[Id][i] = Zombie_Y[Id] - Barrel_Y[i];
                        if(Boom[i]==1'b1 &&  DistX[Id][i]*DistX[Id][i] + DistY[Id][i]*DistY[Id][i] <= damage_range * damage_range)
                        begin
                            if(Zombie_HP[Id] > Barrel_Damage)begin
                                Zombie_HP_in[Id] = Zombie_HP[Id] - Barrel_Damage;
                            end
                            else begin
                                Zombie_HP_in[Id] = 7'b0;
                            end
                            Zombie_Hitten_in[Id] = 1'b1;
                            Hitten_Direction_in[Id] = Rand_num[1:0];
                        end
                    end
                end

                else begin
                    Zombie_Hitten_in[Id] = 1'b0;
                end
            end

            Feedback:
            begin
                Next_State[Id] = Idle1;
                if( Zombie_Exist[Id] == 1'b1 )
                begin
                    //Move Control
                    Zombie_X_in[Id] = Zombie_X[Id] + X_Motion[Id];
                    Zombie_Y_in[Id] = Zombie_Y[Id] + Y_Motion[Id];
                    //Boundary Check
                    if( Zombie_X_in[Id] > Zombie_X_Max )
                            Zombie_X_in[Id] = Zombie_X[Id];
                    if( Zombie_Y_in[Id] > Zombie_Y_Max )
                            Zombie_Y_in[Id] = Zombie_Y[Id];
                    
                    if( Zombie_Hitten[Id] == 1'b0 )
                    begin
                        if( (DistX_1[Id]*DistX_1[Id] + DistY_1[Id]*DistY_1[Id] <= 24*24 && Player_HP[0] != 7'd0 )
                            || (DistX_2[Id]*DistX_2[Id] + DistY_2[Id]*DistY_2[Id] <= 24*24 && Player_HP[1] != 7'd0 ))
                        begin//Hit the Player
                            Zombie_State_in[Id] = 2'd2;                            
                            if(Zombie_State[Id][1] == 1'b1)
                                Zombie_State_in[Id] = 2'b0;
                            X_Motion_in[Id] = 10'b0;
                            Y_Motion_in[Id] = 10'b0;
                        end
                        else
                        begin//Normal movement
                            if( (DistX_1[Id]*DistX_1[Id] + DistY_1[Id]*DistY_1[Id] <= DistX_2[Id]*DistX_2[Id] + DistY_2[Id]*DistY_2[Id] 
                                && Player_HP[0] != 7'd0 && Player_HP[1] != 7'd0) || Player_HP[1] == 7'd0)
                            begin//Move to Player_1 (index 0)
                                if( DistX_1[Id]*DistX_1[Id] > DistY_1[Id]*DistY_1[Id] ) 
                                begin// Move towards X-axis
                                    Y_Motion_in[Id] = 10'd0;
                                    if(Player_X[0]< Zombie_X[Id])
                                    begin
                                        Zombie_Direction_in[Id] = 2'b01;
                                        X_Motion_in[Id] = ~(Zombie_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Zombie_Direction_in[Id] = 2'b11;
                                        X_Motion_in[Id] = Zombie_Step;
                                    end
                                end
                                else
                                begin//Move towards Y_axist
                                    X_Motion_in[Id] = 10'd0;
                                    if(Player_Y[0]< Zombie_Y[Id])
                                    begin
                                        Zombie_Direction_in[Id] = 2'b00;
                                        Y_Motion_in[Id] = ~(Zombie_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Zombie_Direction_in[Id] = 2'b10;
                                        Y_Motion_in[Id] = Zombie_Step; 
                                    end
                                end
                            end
                            else
                            begin
                                if( DistX_2[Id]*DistX_2[Id] > DistY_2[Id]*DistY_2[Id] ) 
                                begin// Move towards X-axis
                                    Y_Motion_in[Id] = 10'd0;
                                    if(Player_X[1]< Zombie_X[Id])
                                    begin
                                        Zombie_Direction_in[Id] = 2'b01;
                                        X_Motion_in[Id] = ~(Zombie_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Zombie_Direction_in[Id] = 2'b11;
                                        X_Motion_in[Id] = Zombie_Step;
                                    end
                                end
                                else
                                begin//Move towards Y_axist
                                    X_Motion_in[Id] = 10'd0;
                                    if(Player_Y[1]< Zombie_Y[Id])
                                    begin
                                        Zombie_Direction_in[Id] = 2'b00;
                                        Y_Motion_in[Id] =  ~(Zombie_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Zombie_Direction_in[Id] = 2'b10;
                                        Y_Motion_in[Id] = Zombie_Step;
                                    end
                                end
                            end
                            //Continuous Walk
                            Zombie_State_in[Id][1] = 1'b0;
                            Zombie_State_in[Id][0] = ~Zombie_State[Id][0];
                        end
                    end
                    else //Being Hitten -> feedback
                    begin
                        Zombie_State_in[Id] = 2'b11;
                        case(Hitten_Direction[Id])
                            2'b00: //To Up
                            begin
                                X_Motion_in[Id] = 10'b0;
                                Y_Motion_in[Id] = ~(Zombie_Hitten_Step) + 10'b1;
                                Zombie_Direction_in[Id] = 2'b10; 
                            end
                            2'b01://To Left
                            begin
                                X_Motion_in[Id] = ~(Zombie_Hitten_Step) + 10'b1;
                                Y_Motion_in[Id] = 10'b0;
                                Zombie_Direction_in[Id] = 2'b11;
                            end
                            2'b10://To Down
                            begin
                                X_Motion_in[Id] = 10'b0;
                                Y_Motion_in[Id] = Zombie_Hitten_Step;
                                Zombie_Direction_in[Id] = 2'b00;
                            end
                            2'b11://To Right
                            begin
                                X_Motion_in[Id] = Zombie_Hitten_Step;
                                Y_Motion_in[Id] = 10'b0;
                                Zombie_Direction_in[Id] = 2'b01;
                            end    
                        endcase
                    end      
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
                Zombie_Hitten_in[Id] = 1'b0;
                if( Bullet_Ready[0] == 1'b1 && Bullet_Ready[1] == 1'b1)
                    Next_State[Id] = Hitten_Judgement; 
            end
        endcase     
 
    end

    end
    endgenerate

endmodule


module Zombie_Generator(
	 input logic Clk,
    input logic Generate,
    input logic [25:0] Zombie_Exist,
    output logic [25:0] Initialization_out
);
	 logic [25:0] Initialization;
	 
    always_ff @( posedge Clk) begin
        Initialization_out <= Initialization;
    end

    always_comb begin 

        Initialization = 26'b0;
        if( Generate == 1'b1 )begin
            if(Zombie_Exist[0]==1'b0)begin
                Initialization[0]=1'b1;
            end
            else begin
                if(Zombie_Exist[1]==1'b0)begin
                    Initialization[1]=1'b1;
                end
                else begin
                    if(Zombie_Exist[2]==1'b0)begin
                        Initialization[2]=1'b1;
                    end
                    else begin
                        if(Zombie_Exist[3]==1'b0)begin
                            Initialization[3]=1'b1;
                        end
                        else begin
                            if(Zombie_Exist[4]==1'b0)begin
                                Initialization[4]=1'b1;
                            end
                            else begin
                                if(Zombie_Exist[5]==1'b0)begin
                                    Initialization[5]=1'b1;
                                end
                                else begin
                                    if(Zombie_Exist[6]==1'b0)begin
                                        Initialization[6]=1'b1;
                                    end
                                    else begin
                                        if(Zombie_Exist[7]==1'b0)begin
                                            Initialization[7]=1'b1;
                                        end
                                        else begin
                                            if(Zombie_Exist[8]==1'b0)begin
                                                Initialization[8]=1'b1;
                                            end
                                            else begin
                                                if(Zombie_Exist[9]==1'b0)begin
                                                    Initialization[9]=1'b1;
                                                end
                                                else begin
                                                    if(Zombie_Exist[10]==1'b0)begin
                                                        Initialization[10]=1'b1;
                                                    end
                                                    else begin
                                                        if(Zombie_Exist[11]==1'b0)begin
                                                            Initialization[11]=1'b1;
                                                        end
                                                        else begin
                                                            if(Zombie_Exist[12]==1'b0)begin
                                                                Initialization[12]=1'b1;
                                                            end
                                                            else begin
                                                                if(Zombie_Exist[13]==1'b0)begin
                                                                    Initialization[13]=1'b1;
                                                                end
                                                                else begin
                                                                    if(Zombie_Exist[14]==1'b0)begin
                                                                        Initialization[14]=1'b1;
                                                                    end
                                                                    else begin
                                                                        if(Zombie_Exist[15]==1'b0)begin
                                                                            Initialization[15]=1'b1;
                                                                        end
                                                                        else begin
                                                                            if(Zombie_Exist[16]==1'b0)begin
                                                                                Initialization[16]=1'b1;
                                                                            end
                                                                            else begin
                                                                                if(Zombie_Exist[17]==1'b0)begin
                                                                                    Initialization[17]=1'b1;
                                                                                end
                                                                                else begin
                                                                                    if(Zombie_Exist[18]==1'b0)begin
                                                                                        Initialization[18]=1'b1;
                                                                                    end
                                                                                    else begin
                                                                                        if(Zombie_Exist[19]==1'b0)begin
                                                                                            Initialization[19]=1'b1;
                                                                                        end
                                                                                        else begin
                                                                                            if(Zombie_Exist[20]==1'b0)begin
                                                                                                Initialization[20]=1'b1;
                                                                                            end
                                                                                            else begin
                                                                                                if(Zombie_Exist[21]==1'b0)begin
                                                                                                    Initialization[21]=1'b1;
                                                                                                end
                                                                                                else begin
                                                                                                    if(Zombie_Exist[22]==1'b0)begin
                                                                                                        Initialization[22]=1'b1;
                                                                                                    end
                                                                                                    else begin
                                                                                                        if(Zombie_Exist[23]==1'b0)begin
                                                                                                            Initialization[23]=1'b1;
                                                                                                        end
                                                                                                        else begin
                                                                                                            if(Zombie_Exist[24]==1'b0)begin
                                                                                                                Initialization[24]=1'b1;
                                                                                                            end
                                                                                                            else begin
                                                                                                                if(Zombie_Exist[25]==1'b0)begin
                                                                                                                    Initialization[25]=1'b1;
                                                                                                                end
                                                                                                                else begin
                                                                                                                    
                                                                                                                end
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
endmodule