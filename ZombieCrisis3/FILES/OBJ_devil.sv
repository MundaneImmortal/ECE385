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
 * Filename:        OBJ_Devil.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module Devil(
    input logic Clk, Reset, 
    input logic frame_clk,
	 input logic Start,
    //Devil control
    input logic [9:0] Initialization_Devil,
    output logic [9:0] Devil_Exist, //one-hot encoding, 1 for live and 0 for dead
    //Devil information
    output logic [1:0] Devil_Direction[10],
    output logic [9:0] Devil_X[10],
    output logic [9:0] Devil_Y[10],
    output logic [6:0] Devil_HP[10],
    output logic [1:0] Devil_State[10], //walk, walk, hit, hitten
    output logic       Devil_Hitten[10],
    output logic [9:0] Ready,
    output logic       Die[10],
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
    input logic [5:0]   Time_Counter[2]
    //Barrel
    // input logic [29:0] Barrel_Exist,
    // input logic [6:0] Barrel_HP[30],
    // input logic [9:0] Barrel_X[30],
    // input logic [9:0] Barrel_Y[30],
    // input logic [6:0] Barrel_Damage,
    // input logic [9:0] Damage_Range,
    // input logic [29:0] Boom

);

    parameter [9:0] Devil_X_Min = 10'd0;
    parameter [9:0] Devil_X_Max = 10'd640;
    parameter [9:0] Devil_Y_Min = 10'd0;
    parameter [9:0] Devil_Y_Max = 10'd480;
    parameter [9:0] Devil_Step = 10'd1;
    parameter [9:0] Devil_Hitten_Step = 10'd5;
    parameter [9:0] Devil_Size = 10'd32;
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
    }State[10], Next_State[10];
    
    logic [9:0] Devil_Direction_in[10];
    logic [9:0] Devil_X_in[10];
    logic [9:0] Devil_Y_in[10];
    logic [6:0] Devil_HP_in[10];
    logic [1:0] Devil_State_in[10];
    logic [9:0] Devil_Exist_in;
    logic       Die_in[10];
    logic [9:0] X_Motion[10], Y_Motion[10];
    logic [9:0] X_Motion_in[10], Y_Motion_in[10];

    
    logic Devil_Hitten_in[10];
    logic [1:0] Hitten_Direction[10];
    logic [1:0] Hitten_Direction_in[10];
    logic [9:0]   Ready_in;
    logic [6:0]     Hurt;
    assign Hurt = Bullet_Damage[0] ;
    
    int DistX_1[10]; 
	 int DistX_2[10];
    int DistY_1[10];
	 int DistY_2[10]; 

    genvar Id;
    generate
    for(Id=0;Id<=9;Id=Id+1)
    begin:xjz

    assign DistX_1[Id] = Devil_X[Id] - Player_X[0];
    assign DistX_2[Id] = Devil_X[Id] - Player_X[1];
    assign DistY_1[Id] = Devil_Y[Id] - Player_Y[0];
    assign DistY_2[Id] = Devil_Y[Id] - Player_Y[1];

    always_ff @( posedge Clk ) begin 
        if(~Start)
        begin
            Devil_Direction[Id] <= 2'd0;
            Devil_X[Id] <= 10'd0;
            Devil_Y[Id] <= 10'd0;
            X_Motion[Id] <= 10'd0;
            Y_Motion[Id] <= 10'd0;
            Devil_HP[Id] <= 10'd0;
            Devil_State[Id] <= 10'd0;
            Devil_Exist[Id] <= 10'd0;
            Ready[Id] <= 1'b0;
            Devil_Hitten[Id] <= 1'b0;
            Die[Id] <= 1'b0;
            State[Id] <= Idle1;
        end
        else
        begin
            if(Devil_Exist[Id] == 1'b0)
            begin
                if(Initialization_Devil[Id]==1)
                begin
                    if( Id%2 == 0 )
                    begin
                        Devil_Direction[Id] <=  2'b01;
                        Devil_X[Id] <= 10'd632;
                    end
                    else
                    begin
                        Devil_Direction[Id] <= 2'b11;
                        Devil_X[Id] <= 10'd0;
                    end
                    Devil_Y[Id] <= 10'd240;
                    X_Motion[Id] <= 10'd0;
                    Y_Motion[Id] <= 10'd0;
                    Devil_HP[Id] <= 7'd127;   
                    Devil_Exist[Id] <= 1'b1;
                    Devil_Hitten[Id] <= 1'b0; 
                    Hitten_Direction[Id] <= 2'b00;
                    Die[Id] <= 1'b0;
                    State[Id] <= Idle1;
                    Ready[Id] <= 1'b1;
                end
                else
                begin
                    Devil_Direction[Id] <= 2'd0;
                    Devil_X[Id] <= 10'd0;
                    Devil_Y[Id] <= 10'd0;
                    X_Motion[Id] <= 10'd0;
                    Y_Motion[Id] <= 10'd0;
                    Devil_HP[Id] <= 10'd0;
                    Devil_State[Id] <= 10'd0;
                    Devil_Exist[Id] <= Devil_Exist_in[Id];
                    Die[Id] <= 1'b0;
                    State[Id] <= Idle1;
                    Ready[Id] <= 1'b1;
                end  
            end
            else//Normal update
            begin
                Devil_Direction[Id] <= Devil_Direction_in[Id];
                Devil_X[Id] <= Devil_X_in[Id];
                Devil_Y[Id] <= Devil_Y_in[Id];
                X_Motion[Id] <= X_Motion_in[Id];
                Y_Motion[Id] <= Y_Motion_in[Id];
                Devil_HP[Id] <= Devil_HP_in[Id];
                Devil_State[Id] <= Devil_State_in[Id];
                Devil_Exist[Id] <= Devil_Exist_in[Id];
                Devil_Hitten[Id] <= Devil_Hitten_in[Id];
                Hitten_Direction[Id] <= Hitten_Direction_in[Id];
                State[Id] <= Next_State[Id];
                Die[Id] <= Die_in[Id];
                Ready[Id] <= Ready_in[Id];                
            end
        end
        
    end

    always_comb begin 
        Devil_Exist_in[Id] = Devil_Exist[Id];
        Devil_State_in[Id] = Devil_State[Id];
        Devil_HP_in[Id] = Devil_HP[Id];
        Devil_X_in[Id] = Devil_X[Id];
        Devil_Y_in[Id] = Devil_Y[Id];
        Devil_Direction_in[Id] = Devil_Direction[Id];
        X_Motion_in[Id] = X_Motion[Id];
        Y_Motion_in[Id] = Y_Motion[Id];
        Devil_Hitten_in[Id] =  Devil_Hitten[Id];
        Hitten_Direction_in[Id] = Hitten_Direction[Id];
		Ready_in[Id] = Ready[Id];
        Die_in[Id] = Die[Id];

        Next_State[Id] = State[Id];         

        if( Devil_HP[Id] == 7'd0 )
            Devil_Exist_in[Id] = 1'b0;

        case(State[Id])
            Hitten_Judgement:
            begin
                Next_State[Id] = Feedback;
                if( (If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b01
                    && (Devil_X[Id]<Player_X[0] && Devil_X[Id]+Range > Player_X[0])
                    && (Devil_Y[Id]+10'd30 > Player_Y[0]+10'd16 && Devil_Y[Id]<Player_Y[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b01
                    && (Devil_X[Id]<Player_X[1] && Devil_X[Id]+Range > Player_X[1])
                    && (Devil_Y[Id]+10'd30 > Player_Y[1]+10'd16 && Devil_Y[Id]<Player_Y[1]+10'd16)))
                begin//To Left
                    Devil_Hitten_in[Id] = 1'b1;
                    if(Devil_HP_in[Id] > Hurt)begin
                        Devil_HP_in[Id] = Devil_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b01;
                    end
                    else begin
                        Devil_HP_in[Id] = 7'b0;
                        if(Devil_HP[Id] > 7'd0)
                            Die_in[Id] = 1'b1;
                    end
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b11
                    && (Devil_X[Id]>Player_X[0] && Devil_X[Id]< Player_X[0]+Range)
                    && (Devil_Y[Id]+10'd30 > Player_Y[0]+10'd16 && Devil_Y[Id]<Player_Y[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b11
                    && (Devil_X[Id]>Player_X[1] && Devil_X[Id]< Player_X[1]+Range)
                    && (Devil_Y[Id]+10'd30 > Player_Y[1]+10'd16 && Devil_Y[Id]<Player_Y[1]+10'd16)))
                begin//To Right
                    if(Devil_HP_in[Id] > Hurt)begin
                        Devil_HP_in[Id] = Devil_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b11;
                    end
                    else begin
                        Devil_HP_in[Id] = 7'b0;
                        if(Devil_HP[Id] > 7'd0)
                            Die_in[Id] = 1'b1;
                    end
                    Devil_Hitten_in[Id] = 1'b1;
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b10
                    &&(Devil_Y[Id]>Player_Y[0] && Devil_Y[Id]< Player_Y[0]+Range)
                    &&(Devil_X[Id]+10'd24 > Player_X[0]+10'd8 && Devil_X[Id]<Player_X[0]+10'd6))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b10
                    &&(Devil_Y[Id]>Player_Y[1] && Devil_Y[Id]< Player_Y[1]+Range)
                    &&(Devil_X[Id]+10'd24 > Player_X[1]+10'd8 && Devil_X[Id]<Player_X[1]+10'd6)))
                begin//To Down
                    if(Devil_HP_in[Id] > Hurt)begin
                        Devil_HP_in[Id] = Devil_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b10;
                    end
                    else begin
                        Devil_HP_in[Id] = 7'b0;
                        if(Devil_HP[Id] > 7'd0)
                            Die_in[Id] = 1'b1;                        
                    end
                    Devil_Hitten_in[Id] = 1'b1;
                end
                else if((If_Shot[0] == 1'b1 && Player_Direction[0] == 2'b00
                    &&(Devil_Y[Id]<Player_Y[0] && Devil_Y[Id]+Range > Player_Y[0])
                    &&(Devil_X[Id]+10'd16 > Player_X[0]+10'd8 && Devil_X[Id]<Player_X[0]+10'd16))
                    || (If_Shot[1] == 1'b1 && Player_Direction[1] == 2'b00
                    &&(Devil_Y[Id]<Player_Y[1] && Devil_Y[Id]+Range > Player_Y[1])
                    &&(Devil_X[Id]+10'd16 > Player_X[1]+10'd24 && Devil_X[Id]<Player_X[1]+10'd16)))
                begin//To Up
                    if(Devil_HP_in[Id] > Hurt)begin
                        Devil_HP_in[Id] = Devil_HP[Id] - Hurt;
                        Hitten_Direction_in[Id] = 2'b00;
                    end
                    else begin
                        Devil_HP_in[Id] = 7'b0;
                        if(Devil_HP[Id] > 7'd0)
                            Die_in[Id] = 1'b1;                    
                    end
                    Devil_Hitten_in[Id] = 1'b1;
                end
                //priority:fire ball
                //priority:barrel

                // else if(Barrel_Exist != 30'b0)
                // begin 
                //     for(int i =0 ; i<30; i = i+1)
                //     begin
                //         DistX[i] = Devil_X[Id] - Barrel_X[i];
                //         DistY[i] = Devil_Y[Id] - Barrel_Y[i];
                //         if(Boom[i]==1'b1 &&  DistX[i]*DistX[i] + DistY[i]*DistY[i] <= Damage_Range)
                //         begin
                //             if(Devil_HP[Id] > Barrel_Damage)begin
                //             Devil_HP_in[Id] = Devil_HP[Id] - Barrel_Damage;
                //             end
                //             else begin
                //                 Devil_HP_in[Id] = 7'b0;
                //             end
                //             Devil_Hitten_in[Id] = 1'b1;
                //         end
                //     end
                // end
                else begin
                    Devil_Hitten_in[Id] = 1'b0;
                end
            end

            Feedback:
            begin
                Next_State[Id] = Idle1;
                if( Devil_Exist[Id] == 1'b1 )
                begin
                    //Move Control
                    Devil_X_in[Id] = Devil_X[Id] + X_Motion[Id];
                    Devil_Y_in[Id] = Devil_Y[Id] + Y_Motion[Id];
                    //Boundary Check
                    if( Devil_X_in[Id] > Devil_X_Max )
                            Devil_X_in[Id] = Devil_X[Id];
                    if( Devil_Y_in[Id] > Devil_Y_Max )
                            Devil_Y_in[Id] = Devil_Y[Id];
                    
                    if( Devil_Hitten[Id] == 1'b0 )
                    begin
                        if( (DistX_1[Id]*DistX_1[Id] + DistY_1[Id]*DistY_1[Id] <= 24*24 && Player_HP[0] != 7'd0 )
                            || (DistX_2[Id]*DistX_2[Id] + DistY_2[Id]*DistY_2[Id] <= 24*24 && Player_HP[1] != 7'd0 ))
                        begin//Hit the Player
                            Devil_State_in[Id] = 2'd2;                            
                            if(Devil_State[Id][1] == 1'b1)
                                Devil_State_in[Id] = 2'b0;
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
                                    if(Player_X[0]< Devil_X[Id])
                                    begin
                                        Devil_Direction_in[Id] = 2'b01;
                                        X_Motion_in[Id] = ~(Devil_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Devil_Direction_in[Id] = 2'b11;
                                        X_Motion_in[Id] = Devil_Step;
                                    end
                                end
                                else
                                begin//Move towards Y_axist
                                    X_Motion_in[Id] = 10'd0;
                                    if(Player_Y[0]< Devil_Y[Id])
                                    begin
                                        Devil_Direction_in[Id] = 2'b00;
                                        Y_Motion_in[Id] = ~(Devil_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Devil_Direction_in[Id] = 2'b10;
                                        Y_Motion_in[Id] = Devil_Step; 
                                    end
                                end
                            end
                            else
                            begin
                                if( DistX_2[Id]*DistX_2[Id] > DistY_2[Id]*DistY_2[Id] ) 
                                begin// Move towards X-axis
                                    Y_Motion_in[Id] = 10'd0;
                                    if(Player_X[1]< Devil_X[Id])
                                    begin
                                        Devil_Direction_in[Id] = 2'b01;
                                        X_Motion_in[Id] = ~(Devil_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Devil_Direction_in[Id] = 2'b11;
                                        X_Motion_in[Id] = Devil_Step;
                                    end
                                end
                                else
                                begin//Move towards Y_axist
                                    X_Motion_in[Id] = 10'd0;
                                    if(Player_Y[1]< Devil_Y[Id])
                                    begin
                                        Devil_Direction_in[Id] = 2'b00;
                                        Y_Motion_in[Id] =  ~(Devil_Step) + 10'b1;
                                    end
                                    else
                                    begin
                                        Devil_Direction_in[Id] = 2'b10;
                                        Y_Motion_in[Id] = Devil_Step;
                                    end
                                end
                            end
                            //Continuous Walk
                            Devil_State_in[Id][1] = 1'b0;
                            Devil_State_in[Id][0] = ~Devil_State[Id][0];
                        end
                    end
                    else //Being Hitten -> feedback
                    begin
                        Devil_State_in[Id] = 2'b11;
                        case(Hitten_Direction[Id])
                            2'b00: //To Up
                            begin
                                X_Motion_in[Id] = 10'b0;
                                Y_Motion_in[Id] = ~(Devil_Hitten_Step) + 10'b1;
                                Devil_Direction_in[Id] = 2'b10; 
                            end
                            2'b01://To Left
                            begin
                                X_Motion_in[Id] = ~(Devil_Hitten_Step) + 10'b1;
                                Y_Motion_in[Id] = 10'b0;
                                Devil_Direction_in[Id] = 2'b11;
                            end
                            2'b10://To Down
                            begin
                                X_Motion_in[Id] = 10'b0;
                                Y_Motion_in[Id] = Devil_Hitten_Step;
                                Devil_Direction_in[Id] = 2'b00;
                            end
                            2'b11://To Right
                            begin
                                X_Motion_in[Id] = Devil_Hitten_Step;
                                Y_Motion_in[Id] = 10'b0;
                                Devil_Direction_in[Id] = 2'b01;
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
                Devil_Hitten_in[Id] = 1'b0;
                Die_in[Id] = 1'b0;
                if( Bullet_Ready[0] == 1'b1 && Bullet_Ready[1] == 1'b1)
                    Next_State[Id] = Hitten_Judgement; 
            end
        endcase     
    end
    end
    endgenerate

endmodule


module Devil_Generator(
	 input logic Clk,
    input logic Generate,
    input logic [9:0] Devil_Exist,
    output logic [9:0] Initialization_Devil
);
	 logic [9:0] Initialization;
	 
    always_ff @( posedge Clk) begin
        Initialization_Devil <= Initialization;
    end

    always_comb begin 

        Initialization = 10'b0;
        if( Generate == 1'b1 )begin
            if(Devil_Exist[0]==1'b0)begin
                Initialization[0]=1'b1;
            end
            else begin
                if(Devil_Exist[1]==1'b0)begin
                    Initialization[1]=1'b1;
                end
                else begin
                    if(Devil_Exist[2]==1'b0)begin
                        Initialization[2]=1'b1;
                    end
                    else begin
                        if(Devil_Exist[3]==1'b0)begin
                            Initialization[3]=1'b1;
                        end
                        else begin
                            if(Devil_Exist[4]==1'b0)begin
                                Initialization[4]=1'b1;
                            end
                            else begin
                                if(Devil_Exist[5]==1'b0)begin
                                    Initialization[5]=1'b1;
                                end
                                else begin
                                    if(Devil_Exist[6]==1'b0)begin
                                        Initialization[6]=1'b1;
                                    end
                                    else begin
                                        if(Devil_Exist[7]==1'b0)begin
                                            Initialization[7]=1'b1;
                                        end
                                        else begin
                                            if(Devil_Exist[8]==1'b0)begin
                                                Initialization[8]=1'b1;
                                            end
                                            else begin
                                                if(Devil_Exist[9]==1'b0)begin
                                                    Initialization[9]=1'b1;
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