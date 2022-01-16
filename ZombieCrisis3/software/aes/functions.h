
void SubBytes(unsigned char* state){
    for (int i=0;i<16;i++){
    	state[i]=aes_sbox[state[i]];  //use loop up table to replace original Byte
    }
}

void ShiftRows(unsigned char* state){
	for (int n=1;n<4;n++){
	    for (int i=1;i<=n;i++){
			    unsigned char temp = state[4*n];
			    for (int j = 0 ; j <= 2 ; j++)
				    state[4*n+j] = state[4*n+j+1];  //left shift
			    state[4*n+3] = temp; //to shift circularly
		    }
	}
}

void MixColumns(unsigned char* state){
    unsigned char* b0,b1,b2,b3;
    for (int i = 0 ; i < 4 ; i++)
    	{
    	//use look up table to get the values of multiplications
    		b0 = gf_mul[state[0*4+i]][0] ^ gf_mul[state[1*4+i]][1] ^ state[2*4+i] ^ state[3*4+i];
    		b1 = state[0*4+i] ^ gf_mul[state[1*4+i]][0] ^ gf_mul[state[2*4+i]][1] ^ state[3*4+i];
    		b2 = state[0*4+i] ^ state[1*4+i] ^ gf_mul[state[2*4+i]][0] ^ gf_mul[state[3*4+i]][1];
    		b3 = gf_mul[state[0*4+i]][1] ^ state[1*4+i] ^ state[2*4+i] ^ gf_mul[state[3*4+i]][0];
    		state[0*4+i] = b0;
    		state[1*4+i] = b1;
    		state[2*4+i] = b2;
    		state[3*4+i] = b3;
    	}
}

unsigned long RotWord(unsigned long w){
	return ((w & 0x00FFFFFF) << 8) | ((w & 0xFF000000) >> 24);
}

unsigned long Subword(unsigned long w){
	unsigned long a0,a1,a2,a3;
	//use the look up table to do substitution
    a0 = aes_sbox[(w & 0xFF000000) >> 24] << 24;
    a1 = aes_sbox[(w & 0x00FF0000) >> 16] << 16;
    a2 = aes_sbox[(w & 0x0000FF00) >> 8] << 8;
    a3 = aes_sbox[(w & 0x000000FF)];
    return a0 | a1 | a2 | a3;
}

void KeyExpansion(unsigned char * key, unsigned long * w, unsigned long Nk, unsigned long Nb, unsigned long Nr){
	unsigned long temp;
	//firstly, fill the original cypher key
	for (int i = 0 ; i < Nk ; i++){
			w[i] = (key[i]<<24 | key[i+4]<<16 | key[i+8]<<8 | key[i+12]);
	}
	for (int j = Nk ; j < Nb*(Nr+1) ; j++){
		temp = w[j-1];
		if (j % Nk == 0){
			temp = SubWord(RotWord(temp)) ^ Rcon[j/Nk];
		}
		w[j] = w[j-Nk] ^ temp;
	}
}

void AddRoundKey(unsigned char * state, unsigned long * keySchedule){
	for (int i = 0 ; i <= 3 ; i++){
	    for (int j = 0 ; j <= 3 ; j++){
	        state[i*4+j] ^= (keySchedule[j] >> (8*(3-i))) & 0xFF;
	    }
	}
}
