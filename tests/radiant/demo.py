from __future__ import division
import io
import struct
from PIL import Image

# Bit Utilities
def bit_mask(size):
    return ((1 << size) - 1)

def bit_extract(value, pos, size):
    return (value >> pos) & bit_mask(size)

def bit_extract_scaled(value, pos, size):
    return bit_extract(value, pos, size) / bit_mask(size)

def bit_insert(value, pos, size, insert_value):
    mask = bit_mask(size)
    value = value & (~(mask << pos))
    value = value | ((insert_value & mask) << pos)
    return value

def bit_insert_scaled(value, pos, size, insert_value):
    return bit_insert(value, pos, size, int(round(insert_value * bit_mask(size))))

# Image Ytilities
def image_a3i5_extract(file_in, file_out, width, height):
    f = io.open(file_in, 'rb')
    data = struct.unpack('<%sB' % (width * height), f.read(width * height))
    
    img = Image.new("RGBA", (width, height));
    n = 0
    for y in xrange(0, height):
        for x in xrange(0, width):
            index = bit_extract(data[n], 0, 5)
            alpha = bit_extract_scaled(data[n], 5, 3)
            img.putpixel((x, y), (0xFF, 0xFF, 0xFF, int(round(alpha * 0xFF))))
            n = n + 1
    img.save(file_out, 'PNG');

def image_a3i5_insert(file_in, file_out, width, height):
    img = Image.open(file_in, 'r')
    n = 0
    items = []
    for y in xrange(0, height):
        for x in xrange(0, width):
            color = img.getpixel((x, y))
            index = 0
            alpha = color[3]
            
            byte = 0
            byte = bit_insert(byte, 0, 5, index)
            byte = bit_insert_scaled(byte, 5, 3, alpha / 0xFF)
            
            items.append(byte)

    f = io.open(file_out, 'wb')
    for n in xrange(0, width * height):
        f.write(struct.pack('<B', items[n]))
    
    #img.save(file_out, 'PNG');

image_a3i5_extract('title_text.ntft', 'file.png', 256, 256)
image_a3i5_insert('file.png', 'title_text.ntft.out', 256, 256)