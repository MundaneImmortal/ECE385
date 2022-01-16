import struct

filename1 = input("What's the image name?1 ")
filename2 = input("What's the image name?2 ")
filename3 = input("What's the image name?3 ")
filename4 = input("What's the image name?4 ")
filename5 = input("What's the image name?5 ")
filename6 = input("What's the image name?6 ")
out = open("./sprite_ram/BOXHEAD" + ".ram", 'wb')
for i in range(1,17):
    f =  open("./sprite_palette/" + filename1 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(1,17):
    f =  open("./sprite_palette/" + filename2 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(1,17):
    f =  open("./sprite_palette/" + filename3 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(1,10):
    f =  open("./sprite_palette/" + filename4 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(1, 5):
    f = open("./sprite_palette/" + filename5 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(1,2):
    f =  open("./sprite_palette/" + filename6 + "_" + str(i) + '.txt', 'r')
    for line in f:
        hex = int("0x" + str(line[0]) + str(line[1]), 16)
        # print(hex)
        s = struct.pack('b', hex)
        out.write(s)
        s = struct.pack('b', 0)
        out.write(s)
    f.close()
for i in range(0,1024):
    s = struct.pack('b', 0)
    out.write(s)
out.close()