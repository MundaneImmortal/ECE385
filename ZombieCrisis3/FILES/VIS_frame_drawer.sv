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
 * Filename:        VIS_frame_drawer.sv
 * History:
 *       finished on 2022-01-04 by Jiazhen Xu
 */

module frame_drawer(
    input logic         Clk, Reset,
    input logic         Ready, // if game judgement completed
    input logic         frame_clk, // 60Hz V-SYNC signal
    input logic         Start,
    //Player Information
    input logic [1:0]   Player_Direction[2],
    input logic [4:0]   Player_Control[2],
    input logic [9:0]   Player_X[2],
                        Player_Y[2],
    input logic         Player_State[2],
    input logic [6:0]   Player_HP[2],
    input logic [1:0]   Weapon[2],
    input logic [8:0]   Bullet_Counter[2],
    input logic         If_Shot[2],
    //Zombie Information
    input logic [25:0] Zombie_Exist,
    input logic [9:0] Zombie_X[26],
    input logic [9:0] Zombie_Y[26],
    input logic [1:0] Zombie_Direction[26],
    input logic [1:0] Zombie_State[26],
    input logic       Zombie_Hitten[26],
    //Devil Information
    input logic [9:0] Devil_Exist,
    input logic [9:0] Devil_X[10],
    input logic [9:0] Devil_Y[10],
    input logic [1:0] Devil_Direction[10],
    input logic [1:0] Devil_State[10],
    input logic       Devil_Hitten[10],
    //RedBox Information
    input logic [9:0] RedBox_Exist,
    input logic [9:0] RedBox_X[10],
    input logic [9:0] RedBox_Y[10],
    //Barrel Information
    input logic [2:0] Barrel_Exist,
    input logic [9:0] Barrel_X[3],
    input logic [9:0] Barrel_Y[3],
    input logic [2:0] Boom,
    // control signal for SRAM
    input logic [15:0]  Data_Read,
    output logic        SRAM_Read,
    output logic [19:0] SRAM_Addr,
    
    // control signal for frame_buffer
    output logic        frame,
    output logic        FB_Write,
    output logic [9:0]  FB_AddrX,
                        FB_AddrY,
    output logic [4:0]  ColorId
    
);
    enum logic [4:0] {
        Preparation,
        Background,
        Wait_Judgement,
        //Object Render
        Player_Render,
        Zombie_Render,
        Devil_Render,
        RedBox_Render,
        Barrel_Render,
        //Effects Render
        Fire_Render,
		Shot_Render,
		Blood_Render,
        Boom_Render,
        //Change frame
        Idle
    } State, Next_State;

    parameter [9:0] Range = 10'd160;

    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
    
    initial begin
        State = Preparation;
    end

    logic [9:0] h_counter, v_counter, h_counter_in, v_counter_in; //max 1024
    logic frame_in;
    logic wait_sram, wait_sram_in;
    logic FB_Write_in;
    logic [9:0] FB_AddrX_in, FB_AddrY_in;
    logic [4:0] ColorId_in;
    logic Player_Id_in;
    logic Player_Id;
    logic [6:0] Zombie_Id;
    logic [6:0] Zombie_Id_in;
    logic [6:0] Devil_Id;
    logic [6:0] Devil_Id_in;
    logic [6:0] Barrel_Id;
    logic [6:0] Barrel_Id_in;
    logic [6:0] RedBox_Id;
    logic [6:0] RedBox_Id_in;

    logic [9:0] Player_HP_Extension[2];
    logic [9:0] Bullet_Counter_Extension[2];
	logic [19:0] Addr_Base;
	 assign Addr_Base = 20'b1;

    // update registers
    always_ff @ (posedge Clk)
    begin
        if (~Start)
        begin
            State <= Next_State;
            wait_sram <= wait_sram_in;
            frame <= frame_in;
            FB_Write <= FB_Write_in;
            FB_AddrX <= FB_AddrX_in;
            FB_AddrY <= FB_AddrY_in;
            h_counter <= h_counter_in;
            v_counter <= v_counter_in;
            ColorId <= ColorId_in;
            Player_Id <= 1'b0;
            Zombie_Id <= 7'b0;
            Barrel_Id <= 7'b0;
            Devil_Id <= 7'b0;
            RedBox_Id <= 7'b0;
        end
        else
        begin
            State <= Next_State;
            wait_sram <= wait_sram_in;
            frame <= frame_in;
            FB_Write <= FB_Write_in;
            FB_AddrX <= FB_AddrX_in;
            FB_AddrY <= FB_AddrY_in;
            h_counter <= h_counter_in;
            v_counter <= v_counter_in;
            ColorId <= ColorId_in;
            Player_Id <= Player_Id_in;
            Zombie_Id <= Zombie_Id_in;
            Barrel_Id <= Barrel_Id_in;
            Devil_Id <= Devil_Id_in;
            RedBox_Id <= RedBox_Id_in;

        end
    end

    always_comb
    begin
        Next_State = State;

        SRAM_Read = 1'b0;
        SRAM_Addr = 20'b0;

        wait_sram_in = 1'b0;
        frame_in = frame;
        FB_Write_in = 1'b0;
        FB_AddrX_in = FB_AddrX;
        FB_AddrY_in = FB_AddrY;

        h_counter_in = h_counter;
        v_counter_in = v_counter;

        ColorId_in = 5'd22;

        Player_Id_in = Player_Id;
        Zombie_Id_in = Zombie_Id;
        Barrel_Id_in = Barrel_Id;
        Devil_Id_in = Devil_Id;
        RedBox_Id_in = RedBox_Id;

        Player_HP_Extension[0] = {{3{1'b0}},{Player_HP[0]>>3}};
        Player_HP_Extension[1] = {{3{1'b0}},{Player_HP[1]>>3}};
        Bullet_Counter_Extension[0] = {{1'b0}, {Bullet_Counter[0]>>3}};
        Bullet_Counter_Extension[1] = {{1'b0}, {Bullet_Counter[1]>>3}};

        unique case (State)

            Preparation:
            begin                
                SRAM_Read = 1'b1;
                SRAM_Addr = (Addr_Base << 16) + (v_counter * 640) + h_counter ; 
                // Use two clk intervals to wait for the data in SRAM
                wait_sram_in = ~wait_sram;
                if(wait_sram)begin
                    FB_Write_in = 1'b1;
                    FB_AddrX_in =  h_counter;
                    FB_AddrY_in =  v_counter;
                    //Image visualization
                    ColorId_in = Data_Read[4:0];
                    
                    h_counter_in = h_counter + 10'd1;
                    if(h_counter_in == 10'd640)
                    begin
                        h_counter_in = 10'd0;
                        v_counter_in = v_counter + 10'd1;
                        if(v_counter_in == 10'd480)
                        begin
                            v_counter_in = 10'd0;
                            Next_State = Idle;
                        end
                    end   
                end
            end

            // Render the background 
            Background:
            begin
                FB_Write_in = 1'b1;
                FB_AddrX_in = h_counter;
                FB_AddrY_in = v_counter;
                if(h_counter >= 10'd8 && h_counter < 10'd632 && v_counter >= 10'd8 && v_counter < 10'd472)
                    ColorId_in = 5'd22;
                else
                    ColorId_in = 5'd21;

                h_counter_in = h_counter + 10'd1;
                if(h_counter_in == 10'd640)
                begin
                    h_counter_in = 10'd0;
                    v_counter_in = v_counter + 10'd1;
                    if(v_counter_in == 10'd480)
                    begin
                        v_counter_in = 10'd0;
                        Next_State = Wait_Judgement;
                    end
                end
            end
				

            Wait_Judgement:
            begin
                if(Ready)
                    Next_State = Blood_Render;
            end

            Blood_Render:
            begin
                if(Zombie_Exist[Zombie_Id] == 1'b1 && Zombie_Hitten[Zombie_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 12)  + (v_counter << 6) + h_counter ; 
                    // Use two clk intervals to wait for the data in SRAM
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = Zombie_X[Zombie_Id] + ~(10'd16) + h_counter;
                        FB_AddrY_in = Zombie_Y[Zombie_Id] + ~(10'd16) + v_counter;
                        FB_Write_in = 1'b1;
                        ColorId_in = Data_Read[4:0];
                        if(ColorId_in == 5'd18)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 64*64
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd64)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd64)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through zombies
                                Zombie_Id_in = Zombie_Id + 7'd1;
                                if(Zombie_Id == 7'd25)
                                begin
                                    Zombie_Id_in = 7'd0;
                                    Next_State = Player_Render;
                                end
                            end
                        end
                    end
                end
                else begin
                    Zombie_Id_in = Zombie_Id + 7'd1;
                    if(Zombie_Id == 7'd25)
                    begin
                        Zombie_Id_in = 7'd0;
                        Next_State = Player_Render;
                    end
                end
            end

            // Render Players 
            Player_Render:
            begin
                if(Player_HP[Player_Id] != 7'd0)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Player_Id << 13) + (((Player_Direction[Player_Id] << 1) + Player_State[Player_Id]) << 10) + (v_counter << 5) + h_counter ; 
                    // Use two clk intervals to wait for the data in SRAM
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                        begin
                        FB_AddrX_in = Player_X[Player_Id] + h_counter;
                        FB_AddrY_in = Player_Y[Player_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        // set white color on Player as transparent
                        if(ColorId_in == 5'd18)
                        begin//HP visualization
                            if( ((Player_HP_Extension[Player_Id]+ 10'd8) > h_counter) && (h_counter > 10'd8)  && ((v_counter >> 1) == 10'd0 ))
                            begin
                                ColorId_in = 5'd23;
                            end
                            else if(Bullet_Counter_Extension[Player_Id] + 10'd8 > h_counter && h_counter > 10'd8 && v_counter == 10'd2)
                            begin
                                ColorId_in =5'd9;
                            end
                            else if ((2'd3-(Weapon[Player_Id]<<1))*4 + 10'd8 > h_counter && h_counter > 10'd8 && v_counter == 10'd3)
                            begin
                            ColorId_in = 5'd24;
                            end
                            else FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through two players
                                Player_Id_in = Player_Id + 1'd1;
                                if(Player_Id == 1'd1)
                                begin
                                    Player_Id_in = 1'd0;
                                    Next_State = RedBox_Render;
                                end
                            end
                        end
                    end
                end
                else begin
                    Player_Id_in = Player_Id + 1'd1;
                    if(Player_Id == 1'd1)
                    begin
                        Player_Id_in = 1'd0;
                        Next_State = RedBox_Render;
                    end
                end
            end
         
            RedBox_Render:
            begin
                if(RedBox_Exist[RedBox_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 11) + (v_counter << 5) + h_counter;
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = RedBox_X[RedBox_Id] + h_counter;
                        FB_AddrY_in = RedBox_Y[RedBox_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        if(ColorId_in == 5'd18)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through RedBoxs
                                RedBox_Id_in = RedBox_Id + 7'd1;
                                if(RedBox_Id == 7'd9)
                                begin
                                    RedBox_Id_in = 7'd0;
                                    Next_State = Zombie_Render;
                                end
                            end
                        end
                    end
                end
                else begin
                    //Loop through RedBoxs
                    RedBox_Id_in = RedBox_Id + 7'd1;
                    if(RedBox_Id == 7'd9)
                    begin
                        RedBox_Id_in = 7'd0;
                        Next_State = Zombie_Render;
                    end
                end
            end

            Zombie_Render:
            begin
                if(Zombie_Exist[Zombie_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 14) +  (((Zombie_Direction[Zombie_Id] << 2)+ Zombie_State[Zombie_Id]) << 10) + (v_counter << 5) + h_counter;
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = Zombie_X[Zombie_Id] + h_counter;
                        FB_AddrY_in = Zombie_Y[Zombie_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        if(ColorId_in == 5'd4)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through Zombies
                                Zombie_Id_in = Zombie_Id + 7'd1;
                                if(Zombie_Id == 7'd25)
                                begin
                                    Zombie_Id_in = 7'd0;
                                    Next_State = Devil_Render;
                                end
                            end
                        end
                    end
                end
                else
                begin
                    Zombie_Id_in = Zombie_Id + 7'd1;
                    if(Zombie_Id == 7'd25)
                    begin
                        Zombie_Id_in = 7'd0;
                        Next_State = Devil_Render;
                    end
                end
            end

            Devil_Render:
            begin
                if(Devil_Exist[Devil_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 15) +  (((Devil_Direction[Devil_Id] << 2)+ Devil_State[Devil_Id]) << 10) + (v_counter << 5) + h_counter;
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = Devil_X[Devil_Id] + h_counter;
                        FB_AddrY_in = Devil_Y[Devil_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        if(ColorId_in == 5'd18)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through Devils
                                Devil_Id_in = Devil_Id + 7'd1;
                                if(Devil_Id == 7'd9)
                                begin
                                    Devil_Id_in = 7'd0;
                                    Next_State = Barrel_Render;
                                end
                            end
                        end
                    end
                end
                else
                begin
                    Devil_Id_in = Devil_Id + 7'd1;
                    if(Devil_Id == 7'd9)
                    begin
                        Devil_Id_in = 7'd0;
                        Next_State = Barrel_Render;
                    end
                end
            end
            
            Barrel_Render:
            begin
                if(Barrel_Exist[Barrel_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (v_counter << 5) + h_counter;
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = Barrel_X[Barrel_Id] + h_counter;
                        FB_AddrY_in = Barrel_Y[Barrel_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        if(ColorId_in == 5'd18)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through Barrels
                                Barrel_Id_in = Barrel_Id + 7'd1;
                                if(Barrel_Id == 7'd2)
                                begin
                                    Barrel_Id_in = 7'd0;
                                    Next_State = Boom_Render;
                                end
                            end
                        end
                    end
                end
                else begin
                    Barrel_Id_in = Barrel_Id + 7'd1;
                    if(Barrel_Id == 7'd2)
                    begin
                        Barrel_Id_in = 7'd0;
                        Next_State = Boom_Render;
                    end
                end
            end

            Boom_Render:
            begin
                if(Boom[Barrel_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 13) + (Addr_Base << 10) + (v_counter << 5) + h_counter;
                    wait_sram_in = ~wait_sram;
                    if(wait_sram)
                    begin
                        FB_AddrX_in = Barrel_X[Barrel_Id] + h_counter;
                        FB_AddrY_in = Barrel_Y[Barrel_Id] + v_counter;
                        //Image visualization
                        ColorId_in = Data_Read[4:0];
                        FB_Write_in = 1'b1;
                        if(ColorId_in == 5'd18)
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through Barrels
                                Barrel_Id_in = Barrel_Id + 7'd1;
                                if(Barrel_Id == 7'd2)
                                begin
                                    Barrel_Id_in = 7'd0;
                                    Next_State = Shot_Render;
                                end
                            end
                        end
                    end
                end
                else begin
                    //Loop through Barrels
                    Barrel_Id_in = Barrel_Id + 7'd1;
                    if(Barrel_Id == 7'd2)
                    begin
                        Barrel_Id_in = 7'd0;
                        Next_State = Shot_Render;
                    end
                end
            end


			Shot_Render:
				begin
					if(If_Shot[Player_Id] == 1'b1)
					begin
                        FB_Write_in = 1'b1;
						ColorId_in = 5'd0;
						case(Player_Direction[Player_Id])
                             2'b00:
                             begin  
                                 v_counter_in = v_counter + 10'd1;
                                 if(Player_Y[Player_Id] + 10'd2 > v_counter)
                                 begin
                                     FB_AddrX_in = Player_X[Player_Id] + 10'd21 + h_counter;
                                     FB_AddrY_in = Player_Y[Player_Id] + 10'd2 + (~v_counter) +1;
                                 end
                                 if(v_counter ==  Range)
                                 begin
                                     v_counter_in = 10'd0;
                                     Player_Id_in = Player_Id + 1'd1;
                                     if(Player_Id == 1'd1)
                                     begin
                                         Player_Id_in = 1'd0;
                                         Next_State = Fire_Render;
                                     end
                                 end    
                             end
                             2'b01:
                             begin
                                 h_counter_in = h_counter + 10'd1;
                                 if(Player_X[Player_Id] + 10'd0 > h_counter)
                                 begin
                                     FB_AddrX_in = Player_X[Player_Id] + 10'd0 + (~h_counter) +1;
                                     FB_AddrY_in = Player_Y[Player_Id] + 10'd10 + v_counter;
                                 end
                                 if(h_counter ==  Range)
                                 begin
                                     h_counter_in = 10'd0;
                                     Player_Id_in = Player_Id + 1'd1;
                                     if(Player_Id == 1'd1)
                                     begin
                                         Player_Id_in = 1'd0;
                                         Next_State = Fire_Render;
                                     end
                                 end
                             end
                             2'b10:
                             begin
                                 v_counter_in = v_counter + 10'd1;
                                 if(Player_Y[Player_Id] + 10'd30 + v_counter < 10'd480)
                                 begin
                                     FB_AddrX_in = Player_X[Player_Id] + 10'd8 + h_counter;
                                     FB_AddrY_in = Player_Y[Player_Id] + 10'd30 + v_counter;
                                 end
                                 if(v_counter ==  Range)
                                 begin
                                     v_counter_in = 10'd0;
                                     Player_Id_in = Player_Id + 1'd1;
                                     if(Player_Id == 1'd1)
                                     begin
                                         Player_Id_in = 1'd0;
                                         Next_State = Fire_Render;
                                     end
                                 end
                             end
                             2'b11:
                             begin
                                 h_counter_in = h_counter + 10'd1;
                                 if(Player_X[Player_Id] + 10'd0 + h_counter < 10'd640)
                                 begin
                                     FB_AddrX_in = Player_X[Player_Id] + 10'd32 + h_counter;
                                     FB_AddrY_in = Player_Y[Player_Id] + 10'd10 + v_counter;
                                 end
                                 if(h_counter ==  Range)
                                 begin
                                     h_counter_in = 10'd0;
                                     Player_Id_in = Player_Id + 1'd1;
                                     if(Player_Id == 1'd1)
                                     begin
                                         Player_Id_in = 1'd0;
                                         Next_State = Fire_Render;
                                     end
                                 end
                             end
                         endcase
					end
                    else begin
                        //Loop through two players
                        Player_Id_in = Player_Id + 1'd1;
                        if(Player_Id == 1'd1)
                        begin
                            Player_Id_in = 1'd0;
                            Next_State = Fire_Render;
                        end
                    end
						
				end

            Fire_Render:
            begin//Prop_6
                if(If_Shot[Player_Id] == 1'b1)
                begin
                    SRAM_Read = 1'b1;
                    wait_sram_in = ~wait_sram;
                    case(Player_Direction[Player_Id])
                        2'b00:
                        begin
                            SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 13) + (Addr_Base << 12) + (v_counter << 5) + h_counter ; 
                            FB_AddrX_in = Player_X[Player_Id] + 10'd7 + h_counter;
                            FB_AddrY_in = Player_Y[Player_Id] + ~(10'd20) + v_counter;
                        end
                        2'b01:
                        begin
                            SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 13) + (Addr_Base << 12) + (Addr_Base << 10) + (v_counter << 5) + h_counter ;
                            FB_AddrX_in = Player_X[Player_Id] + ~(10'd22) + h_counter;
                            FB_AddrY_in = Player_Y[Player_Id] + ~(10'd6) + v_counter;
                        end
                        2'b10:
                        begin
                            SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 13) + (Addr_Base << 12) + (Addr_Base << 11) + (v_counter << 5) + h_counter ;
                            FB_AddrX_in = Player_X[Player_Id] + ~(10'd6) + h_counter;
                            FB_AddrY_in = Player_Y[Player_Id] + 10'd18 + v_counter;
                        end
                        2'b11:
                        begin
                            SRAM_Addr = (Addr_Base << 15) +  (Addr_Base << 14) + (Addr_Base << 13) + (Addr_Base << 12) + (Addr_Base << 11) + (Addr_Base << 10) + (v_counter << 5) + h_counter ;
                            FB_AddrX_in = Player_X[Player_Id] + 10'd20 + h_counter;
                            FB_AddrY_in = Player_Y[Player_Id] + ~(10'd4) + v_counter;
                        end
                    endcase
                    if(wait_sram)
                    begin
                        FB_Write_in = 1'b1;
                        ColorId_in = Data_Read[4:0];
                        if(ColorId_in == 5'd18 )
                        begin
                            FB_Write_in = 1'b0;
                        end
                        //Loop through 32*32
                        h_counter_in = h_counter + 10'd1;                                     
                        if(h_counter_in == 10'd32)
                        begin
                            h_counter_in = 10'd0;
                            v_counter_in = v_counter + 10'd1;
                            if(v_counter_in == 10'd32)
                            begin
                                v_counter_in = 10'd0;
                                //Loop through two players
                                Player_Id_in = Player_Id + 1'd1;
                                if(Player_Id == 1'd1)
                                begin
                                    Player_Id_in = 1'd0;
                                    Next_State = Idle;
                                end
                            end
                        end
                    end
                end
                else begin
                    //Loop through two players
                    Player_Id_in = Player_Id + 1'd1;
                    if(Player_Id == 1'd1)
                    begin
                        Player_Id_in = 1'd0;
                        Next_State = Idle;
                    end
                end
            end

            Idle:
            begin
                if(frame_clk_rising_edge)
                begin
                    if(Start)
                        Next_State = Background;
                    else
                        Next_State = Preparation;
                    frame_in = ~frame;
                end
            end

            default: ;
        endcase
    end

endmodule
