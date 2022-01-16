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
 * Filename:        Sys_gameprocess.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module TimeFlow(
    input logic Clk, Reset, 
    input logic frame_clk,
    //control signal
    input logic Start,
    input logic [25:0] Zombie_Exist,
	 input logic [9:0] Devil_Exist,
    input logic [6:0] Player_HP[2],
    output logic Generate[2],
    output logic [2:0] Level,
    output logic Over
);

    parameter [9:0] Zombie_Base = 10'd30;
    parameter [9:0] Devil_Base = 10'd2;
    parameter [9:0] Interval_Time = 10'd600;
    parameter [9:0] Generate_Time = 10'd24;

    logic [9:0] Zombie_Counter;
    logic [9:0] Devil_Counter;
    logic [9:0] Zombie_Num;
    logic [9:0] Devil_Num;
    logic [9:0] Interval_Counter;
                                                                                                                                                              
    logic [9:0] Zombie_Counter_in;
    logic [9:0] Devil_Counter_in;
    logic [9:0] Zombie_Num_in;
    logic [9:0] Devil_Num_in;
    logic [9:0] Interval_Counter_in;
    logic [2:0] Level_in;
	 logic 		 Over_in;
    logic Zombie_Finish,Devil_Finish;

    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end

    int level;
    int zombie_base = 50;
    int zombie_num;
    assign level = Level;
    assign zombie_num = Zombie_Num;

    enum logic[1:0]{
        Generating,
        Waiting,
        Interval,
        Gameover
    }State, Next_State;

    always_ff @( posedge Clk ) begin 
        if(Start) //We control the start with Reset
        begin
            Zombie_Counter <= Zombie_Counter_in;
            Devil_Counter <= Devil_Counter_in;
            Zombie_Num <= Zombie_Num_in;
            Devil_Num <= Devil_Num_in;
            Interval_Counter <= Interval_Counter_in;
            Level <= Level_in;
            State <= Next_State;
            Over <= Over_in;
        end
        else 
        begin
            Zombie_Counter <= 10'd0;
            Devil_Counter <= 10'd0;
            Zombie_Num <= 10'd0;
            Devil_Num <= 10'd0;
            Interval_Counter <= 10'd0;
            Level <= 3'd1;
            State <= Gameover;
            Over <= 1'b0;
        end
    end

    always_comb begin 
        Next_State = State;
        Zombie_Counter_in = Zombie_Counter;
        Devil_Counter_in = Devil_Counter;
        Interval_Counter_in = Interval_Counter;
        Zombie_Num_in = Zombie_Num;
        Devil_Num_in = Devil_Num;
        Level_in = Level;
        Zombie_Finish = 1'b0;
        Devil_Finish = 1'b0;
        Over_in = 1'b0;
        Generate[0] = 1'b0;
        Generate[1] = 1'b0;
        if(frame_clk_rising_edge)
        begin
            unique case(State)
                Generating:
                begin
                    if((Player_HP[0] | Player_HP[1]) == 7'b0)
                    begin
                        Over_in = 1;
                        Next_State = Gameover;
                    end
                    else begin
                        if(zombie_num == level * zombie_base)
                        begin
                            Zombie_Finish = 1'b1;
                        end
                        else
                        begin
                            Zombie_Counter_in = Zombie_Counter + 10'd1;
                            if(Zombie_Counter == Generate_Time)
                            begin
                                if( Zombie_Exist == {26{1'b1}})
                                begin
                                    Zombie_Counter_in = Generate_Time;
                                end
                                else begin
                                    Generate[0] = 1'b1;
                                    Zombie_Num_in = Zombie_Num + 10'd1;
                                    Zombie_Counter_in = 10'd0;
                                end
                            end
                        end

                        if(Devil_Num == level * Devil_Base)
                        begin
                            Devil_Finish = 1'b1;
                        end
                        else
                        begin
                            Devil_Counter_in = Devil_Counter + 10'd1;
                            if(Devil_Counter == (Generate_Time << 3 ))
                            begin
                                if(Devil_Exist == {10{1'b1}})
                                begin
                                    Devil_Counter_in = (Generate_Time << 3);
                                end
                                else begin
                                    Generate[1] = 1'b1;
                                    Devil_Num_in = Devil_Num + 10'd1;
                                    Devil_Counter_in = 10'd0;
                                end
                            end
                        end
                        
                        if(Devil_Finish == 1'b1 && Zombie_Finish == 1'b1)
                        begin
                            Next_State = Waiting;
                        end
                    end
                end

                Waiting:
                begin
                    if( Zombie_Exist == 26'b0 && Devil_Exist == 10'b0) 
                    begin
                        Next_State = Interval;
                    end
                end

                Interval:
                begin
                    Interval_Counter_in = Interval_Counter + 10'd1;
                    if(Interval_Counter == Interval_Time)
                    begin
                        Interval_Counter_in = 10'd0;
                        Level_in = Level + 3'd1;
                        Devil_Num_in = 10'd0;
                        Zombie_Num_in = 10'd0;
                        Next_State = Generating;
                        if(Level == 3'd4)
                        begin
                            Over_in = 1;
                            Next_State = Gameover;
                        end
                    end
                end

                Gameover:
                begin
                    Over_in = 0;                        
                    Level_in = 3'd1;
                    Next_State = Generating;
                end

            endcase
        end
    end

endmodule