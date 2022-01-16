module palette (
    input logic [5:0] ColorId,
    output logic [7:0] VGA_R, VGA_G, VGA_B
);
    // Output colors to VGA
    always_comb
    begin
        case(ColorId)
            5'd0:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h00;
                VGA_B = 8'h00;
            end
            5'd1:
            begin
                VGA_R = 8'h08;
                VGA_G = 8'h4a;
                VGA_B = 8'h00;
            end
            5'd2:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h52;
                VGA_B = 8'h08;
            end
            5'd3:
            begin
                VGA_R = 8'hb5;
                VGA_G = 8'hef;
                VGA_B = 8'hef;
            end
            5'd4:
            begin
                VGA_R = 8'h8c;
                VGA_G = 8'hd6;
                VGA_B = 8'h00;
            end
            5'd5:
            begin
                VGA_R = 8'h6b;
                VGA_G = 8'h08;
                VGA_B = 8'h00;
            end
            5'd6:
            begin
                VGA_R = 8'h59;
                VGA_G = 8'h0d;
                VGA_B = 8'h79;
            end
            5'd7:
            begin
                VGA_R = 8'h9c;
                VGA_G = 8'h4a;
                VGA_B = 8'h00;
            end
            5'd8:
            begin
                VGA_R = 8'hf1;
                VGA_G = 8'h5b;
                VGA_B = 8'h3e;
            end
            5'd9:
            begin
                VGA_R = 8'h42;
                VGA_G = 8'h42;
                VGA_B = 8'hff;
            end
            5'd10:
            begin
                VGA_R = 8'he7;
                VGA_G = 8'he7;
                VGA_B = 8'h94;
            end
            5'd11:
            begin
                VGA_R = 8'hb5;
                VGA_G = 8'hf7;
                VGA_B = 8'hce;
            end
            5'd12:
            begin
                VGA_R = 8'h6b;
                VGA_G = 8'h6b;
                VGA_B = 8'h00;
            end
            5'd13:
            begin
                VGA_R = 8'h5a;
                VGA_G = 8'h00;
                VGA_B = 8'h7b;
            end
            5'd14:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h52;
                VGA_B = 8'h00;
            end
            5'd15:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h42;
                VGA_B = 8'h4a;
            end
            5'd16:
            begin
                VGA_R = 8'he7;
                VGA_G = 8'h9c;
                VGA_B = 8'h21;
            end
            5'd17:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h8c;
                VGA_B = 8'h31;
            end
            5'd18:
            begin
                VGA_R = 8'hff;
                VGA_G = 8'hff;
                VGA_B = 8'hff;
            end
            5'd19:
            begin
                VGA_R = 8'had;
                VGA_G = 8'had;
                VGA_B = 8'had;
            end
            5'd20:
            begin
                VGA_R = 8'hb5;
                VGA_G = 8'h31;
                VGA_B = 8'h21;
            end
            5'd21:
            begin
                VGA_R = 8'h63;
                VGA_G = 8'h63;
                VGA_B = 8'h63;
            end
            5'd22: //background
				begin
                VGA_R = 8'hdb;
                VGA_G = 8'hcc;
                VGA_B = 8'hb7;					
				end
            5'd23://HP
            begin
                VGA_R = 8'h1A;
                VGA_G = 8'hCC;
                VGA_B = 8'h23;
            end
				5'd24:
				begin
					VGA_R = 8'hff;
                VGA_G = 8'h00;
                VGA_B = 8'h00;
				end
            default:
            begin
                VGA_R = 8'h00;
                VGA_G = 8'h00;
                VGA_B = 8'h00;
            end
        endcase
    end

endmodule
