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
 * Filename:        OBJ_RedBox.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module RedBox(
    //System Signal
    input logic Clk, Start,
	input logic frame_clk,
    //Control Signal
    output logic [9:0] RedBox_Exist,
    output logic [9:0] RedBox_X[10],
    output logic [9:0] RedBox_Y[10],
    output logic [9:0] Replenish,
    //Interaction
    //Devil Information
    input logic Die[10],
    input logic [9:0] Devil_X[10],
    input logic [9:0] Devil_Y[10],
    //Player_Information
    input logic [9:0] Player_Y[2],
    input logic [9:0] Player_X[2]

);

    logic [9:0] RedBox_Exist_in;
	logic [9:0] RedBox_X_in[10];
    logic [9:0] RedBox_Y_in[10];
    logic [9:0] Replenish_in;
    int DistX[2][10], DistY[2][10];

    enum logic [1:0] {
        Judge,
        Idle1,
        Idle2
    }State[10], Next_State[10];

    //Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end 

    always_ff @(posedge Clk)begin
        if(Start)
        begin
            RedBox_Exist <= RedBox_Exist_in;            
            RedBox_X <= RedBox_X_in;
            RedBox_Y <= RedBox_Y_in; 
            Replenish <= Replenish_in;
            State[0] <= Next_State[0];
            State[1] <= Next_State[1];
            State[2] <= Next_State[2];
            State[3] <= Next_State[3];
            State[4] <= Next_State[4];
            State[5] <= Next_State[5];
            State[6] <= Next_State[6];
            State[7] <= Next_State[7];
            State[8] <= Next_State[8];
            State[9] <= Next_State[9];
        end
        else begin
            RedBox_Exist <= 10'b0;
            Replenish <= 1'b0;
            State[0] <= Idle1;
            State[1] <= Idle1;
            State[2] <= Idle1;
            State[3] <= Idle1;
            State[4] <= Idle1;
            State[5] <= Idle1;
            State[6] <= Idle1;
            State[7] <= Idle1;
            State[8] <= Idle1;
            State[9] <= Idle1;
        end 
    end
    

    always_comb begin
        for(int i=0; i<10; i=i+1)
        begin
            Replenish_in[i] = Replenish[i];
            RedBox_X_in[i] = RedBox_X[i];
            RedBox_Y_in[i] = RedBox_Y[i];
            RedBox_Exist_in[i] = RedBox_Exist[i];
            DistX[0][i] = Player_X[0] - RedBox_X[i];
            DistX[1][i] = Player_X[1] - RedBox_X[i];
            DistY[0][i] = Player_Y[0] - RedBox_Y[i];
            DistY[1][i] = Player_Y[1] - RedBox_Y[i];
            case(State[i])
                Judge:
                begin
                    if(RedBox_Exist[i] == 1'b1)
                    begin
                        if(DistX[0][i]*DistX[0][i] + DistY[0][i]*DistY[0][i] <= 64
                        || DistX[1][i]*DistX[1][i] + DistY[1][i]*DistY[1][i] <= 64)
                        begin
                            RedBox_Exist_in[i] = 1'b0;
                            Replenish_in = 1'b1;
                        end
                    end
                    else begin
                        if( Die[i] == 1'b1 )
                        begin
                            RedBox_Exist_in[i] = 1'b1;
                            RedBox_X_in[i] = Devil_X[i];
                            RedBox_Y_in[i] = Devil_Y[i];
                        end
                    end
                    Next_State[i] = Idle1;
                end

                Idle1:
                begin
                    if (frame_clk_rising_edge)
                        Next_State[i] = Idle2;
                end

                Idle2:
                begin
                    Replenish_in = 1'b0;
                    Next_State[i] = Judge;
                end
				endcase
        end
    end

endmodule