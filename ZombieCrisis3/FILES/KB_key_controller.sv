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
 * Filename:        key_controller.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */


module key_controller(
    input logic        Clk, Reset,
    input logic [7:0]  keycode,
    input logic        press, // 1: key pressed, 0: key released
    output logic [4:0] player_0, // {1'change weapon, 1'fire, 1' is_move, 2'move_direction}
                       player_1,
    output logic [1:0] CONTROL // for both, 1: work 0: not work 
);

    // player1: w: 1D, s: 1B, a: 1C, d: 23, q:15, space:29
    // player2: up: 75, down: 72, left: 6B, right: 74, 1:69, 5:73
    // ENTER: 5A  ESC: 76

logic [2:0] player_1_move, player_2_move;
logic player_1_fire, player_2_fire;
logic player_1_weapon, player_2_weapon; //1 for change and 0 for not change.

logic [2:0] player_1_move_in, player_2_move_in;
logic player_1_fire_in, player_2_fire_in;
logic player_1_weapon_in, player_2_weapon_in;



logic ENTER, ESC;

 logic press_delayed, press_rising_edge;
always_ff @ (posedge Clk) begin
    press_delayed <= press;
    press_rising_edge <= (press == 1'b1) && (press_delayed == 1'b0);
end    


always_ff @(posedge Clk) begin
    player_1_move <= player_1_move_in;
    player_2_move <= player_2_move_in;
    player_1_fire <= player_1_fire_in;
    player_2_fire <= player_2_fire_in;
    player_1_weapon <= player_1_weapon_in;
    player_2_weapon <= player_2_weapon_in;

end

always_comb begin
    player_1_weapon_in = player_1_weapon;
    player_2_weapon_in = player_2_weapon;
    player_1_fire_in = player_1_fire;
    player_1_move_in = player_1_move;
    player_2_fire_in = player_2_fire;
    player_2_move_in = player_2_move;

    ENTER = 1'b0;
    ESC = 1'b0;
    case (keycode)
    //change weapons
        8'h15: //q
        begin
            if (press) 
                player_1_weapon_in = 1'b1;
            else 
                player_1_weapon_in = 1'b0;
        end
        8'h69: //1
        begin
            if (press) 
                    player_2_weapon_in = 1'b1;
				else 
					player_2_weapon_in = 1'b0;
        end
    //move & shot
        8'h1d: // w
        begin
            if (press) 
					player_1_move_in = 3'b100;
            else
            begin
                if (player_1_move == 3'b100) 
						player_1_move_in = 3'b000;
            end
        end
        8'h1b: // s
        begin
            if (press)
                player_1_move_in = 3'b110;
            else
            begin
                if (player_1_move == 3'b110) 
						player_1_move_in = 3'b000;
            end
        end
        8'h1c: // a
        begin
            if (press)
                player_1_move_in = 3'b101;
            else
            begin
                if (player_1_move == 3'b101) 
						player_1_move_in = 3'b000;
            end
        end
        8'h23: // d
        begin
            if (press)
                player_1_move_in = 3'b111;
            else
            begin
                if (player_1_move == 3'b111)  
						player_1_move_in = 3'b000;
            end
        end
        8'h29: // space
        begin
            if (press) 
					player_1_fire_in = 1'b1;
            else 
					player_1_fire_in = 1'b0;
        end
        8'h75: // up
        begin
            if (press) 
					player_2_move_in = 3'b100;
            else
            begin
                if (player_2_move == 3'b100) 
						player_2_move_in = 3'b000;
            end
        end
        8'h72: // down
        begin
            if (press) 
					player_2_move_in = 3'b110;
            else
            begin
                if (player_2_move == 3'b110) 
						player_2_move_in = 3'b000;
            end
        end
        8'h6b: // left
        begin
            if (press) 
					player_2_move_in = 3'b101;
            else
            begin
                if (player_2_move == 3'b101) 
						player_2_move_in = 3'b000;
            end
        end
        8'h74: // right
        begin
            if (press) 
					player_2_move_in = 3'b111;
            else
            begin
                if (player_2_move == 3'b111) 
						player_2_move_in = 3'b000;
            end
        end
        8'h73: // 5(numpad)
        begin
            if (press) 
					player_2_fire_in = 1'b1;
            else 
					player_2_fire_in = 1'b0;
        end
    //interface control  ENTER: 5A  ESC: 76
        8'h5a: //ENTER
        begin
            if(press) 
					ENTER = 1'b1;
            else 
					ENTER = 1'b0;
        end
        8'h76: //ESC
        begin
            if(press) 
					ESC = 1'b1;
            else 
					ESC = 1'b0;
        end
        default:    ;

		

    endcase
end

assign CONTROL = {ESC, ENTER};
assign player_0 = {player_1_weapon, player_1_fire, player_1_move};
assign player_1 = {player_2_weapon, player_2_fire, player_2_move};
endmodule
