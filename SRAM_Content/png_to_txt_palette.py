from PIL import Image
from collections import Counter
from scipy.spatial import KDTree
import numpy as np
def hex_to_rgb(num):
    hex = str(num)
    return int(hex[0:4], 16), int(('0x' + hex[4:6]), 16), int(('0x' + hex[6:8]), 16)
def rgb_to_hex(rgb):
    return "0x%02x%02x%02x" %(rgb[0], rgb[1], rgb[2])
filename = input("What's the image name? ")
for i in range(1,5):
    im = Image.open("./sprite_originals/" + filename+  "_" + str(i)+ ".png") #Can be many different formats.
    im = im.convert("RGB")
    # pix = im.load()
    # pix_freqs = Counter([pix[x, y] for x in range(im.size[0]) for y in range(im.size[1])])
    # pix_freqs_sorted = sorted(pix_freqs.items(), key=lambda x: x[1])

    palette_hex = []
    palette = open("./palette/palette.txt", "r")
    for line in palette:
        palette_hex.append(line)
    palette_rgb = [hex_to_rgb(color) for color in palette_hex]
    pixel_tree = KDTree(palette_rgb)

    # print palette.txt
    # outFile = open("./palette/" + filename + '_palette.txt', 'w')
    # i = 0
    # for rgb in palette_rgb:
    #     outFile.write(rgb_to_hex(rgb) + '\n')
    #     i += 1
    # print(str(i) + ' colors in palette')

    outImg = Image.new('RGB', im.size, color='white')
    outFile = open("./sprite_palette/" + filename + "_" + str(i)+ '.txt', 'w')

    for y in range(im.size[1]):
        for x in range(im.size[0]):
            pixel = im.getpixel((x,y))
            index = pixel_tree.query(pixel)[1]
            outImg.putpixel((x,y), palette_rgb[index])
            outFile.write("%02x\n" %(index))
    outFile.close()
    outImg.save("./sprite_converted/" + filename + str(i)+ ".png" )
    im.close()
