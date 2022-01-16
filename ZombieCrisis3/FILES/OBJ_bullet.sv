
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
 * Filename:        OBJ_bullet.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */


module bullet(
    input logic         Clk, Reset,
    input logic         frame_clk,// 60Hz V-SYNC signal
	input logic 			Start,

    input logic         Die[10],
    input logic         Replenish,
    input logic [4:0]   Player_Control[2],
    input logic [6:0]   Player_HP[2],
    input logic [1:0]   Weapon[2],
    input logic [9:0]   Player_X[2],
                        Player_Y[2],
    input logic [9:0]   RedBox_X[10],
    input logic [9:0]   RedBox_Y[10],
    input logic [9:0]   RedBox_Exist,
    output logic [5:0]   Bullet_Interval[2],
    output logic [6:0]   Bullet_Damage[2],
    output logic [8:0]   Bullet_Counter[2],
    output logic [5:0]   Time_Counter[2],
    output logic         If_Shot[2], //1 for yes and 0 for no;
    output logic         Ready[2]
);
    parameter [5:0] Base_Interval = 6'd5;
    parameter [6:0] Base_Damage = 6'd5;
    parameter [8:0] Base_Number = 9'd128;
	 
	 
    logic [5:0]   Bullet_Interval_in[2];
    logic [6:0]   Bullet_Damage_in[2];
    logic [8:0]   Bullet_Counter_in[2];
    logic         If_Shot_in[2];

    
    logic [5:0]  Time_Counter_in[2];

    logic Ready_in[2];

    enum logic [1:0] {
        Shoot,
        Finish
    }State[2], Next_State[2];

    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end    

	genvar Id; 
    generate
    for(Id=0;Id<2;Id=Id+1)
    begin:xjz
 
    always_ff @ (posedge Clk) 
    begin
        if(~Start)
        begin
            Bullet_Interval[Id] <= Base_Interval;
            Bullet_Damage[Id] <= Base_Damage;
            Bullet_Counter[Id] <= Base_Number;
            If_Shot[Id] <= 1'b0;
            Time_Counter[Id] <= 6'd0;
            Ready[Id] <= 1'b0;
            State[Id] <= Finish;
        end
        else 
        begin
            Bullet_Interval[Id] <= Bullet_Interval_in[Id];
            Bullet_Damage[Id] <= Bullet_Damage_in[Id];
            Bullet_Counter[Id] <= Bullet_Counter_in[Id];
            If_Shot[Id] <= If_Shot_in[Id];
            Time_Counter[Id] <= Time_Counter_in[Id];
            Ready[Id] <= Ready_in[Id];
            State[Id] <= Next_State[Id];
        end
    end

    always_comb begin
		//default logic
        If_Shot_in[Id] = If_Shot[Id];
        Time_Counter_in[Id] = Time_Counter[Id];
        Bullet_Interval_in[Id] = Base_Interval;
        Bullet_Damage_in[Id] = Base_Damage;
        Bullet_Counter_in[Id] = Bullet_Counter[Id];

        Next_State[Id] = State[Id];
        Ready_in[Id] = Ready[Id];

        case(State[Id])
            Shoot:
            begin
                Next_State[Id] = Finish;
				Ready_in[Id] = 1'b1;
                if(Player_HP[Id] != 7'b0)
                begin
                    //Replenish the Bullet Number
                    if(Replenish == 1'b1 || Die[0]|Die[1]|Die[2]|Die[3]|Die[4]|Die[5]|Die[6]|Die[7]|Die[8]|Die[9] == 1'b1)
                    begin
                        Bullet_Counter_in[Id] = Base_Number;
                    end
                    else begin
                        if(If_Shot[Id] == 1'b1) 
                        begin
                            Bullet_Counter_in[Id] =  Bullet_Counter[Id] - 9'b1;
                            if(Bullet_Counter[Id] == 9'b0)
                            begin
                                Bullet_Counter_in[Id] = 9'b0;
                            end
                            If_Shot_in[Id] = 1'b0;
                        end
                        else
                        begin
                            if(Player_Control[Id][3] == 1'b1 && Weapon[Id] == 2'b00)
                            begin
                                Time_Counter_in[Id] = Time_Counter[Id] + 6'b1;
                                if(Time_Counter[Id] == Bullet_Interval[Id])
                                begin
                                    if(Bullet_Counter[Id] != 9'b0)
                                    begin
                                        If_Shot_in[Id] = 1'b1;
                                    end  
                                    Time_Counter_in[Id] = 6'b0;
                                end
                            end
                        end
                    end
                end
                else 
                begin
                    Bullet_Counter_in[Id] = 9'b0;
                    If_Shot_in[Id] = 1'b0;
                end
            end

            Finish:
            begin
                Ready_in[Id] = 1'b1;
                if (frame_clk_rising_edge && Ready[Id])
                begin
                    Ready_in[Id] = 1'b0;
                    Next_State[Id] = Shoot;
                end
                if(Replenish == 1'b1)
                begin
                    Bullet_Counter_in[Id] = Bullet_Counter[Id] + 9'd64;
                end
            end

        endcase
    end
    end
    endgenerate
endmodule




