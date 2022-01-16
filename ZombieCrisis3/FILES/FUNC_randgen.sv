
//Generate a 8_bit Rand_num

module RANGEN(
    input logic Clk,
    input logic Start,

    output logic [7:0] Rand_num
);

    always@(posedge Clk)
    begin
        if( ~Start )
            Rand_num <=8'd101;    /*load the initial value when load is active*/
        else
            begin
                Rand_num[0] <= Rand_num[7];
                Rand_num[1] <= Rand_num[0];
                Rand_num[2] <= Rand_num[1];
                Rand_num[3] <= Rand_num[2];
                Rand_num[4] <= Rand_num[3]^Rand_num[7];
                Rand_num[5] <= Rand_num[4]^Rand_num[7];
                Rand_num[6] <= Rand_num[5]^Rand_num[7];
                Rand_num[7] <= Rand_num[6];
            end            
    end
endmodule