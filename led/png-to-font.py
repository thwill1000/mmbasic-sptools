from PIL import Image

img = Image.open('tom-thumb-new.png')
print(img.format, img.size, img.mode)
img_w, img_h = img.size

first = 20
last = 126
glyph_w = 4
glyph_h = 6

out = open('tt4x6.fnt', 'w', newline = '\n')

print("{}, {}, {}, {}".format(glyph_h, glyph_w, first, last), file = out)

num = 0
y = 0
while (y < img_h):
  x = 0
  while (x < img_w):
    if (num >= first and num <= last):
      glyph = img.crop((x, y, x + glyph_w, y + glyph_h))
      pixel = 0
      for i in glyph.getdata():
        r, g, b = i
        if r == 0:
          print("X", end = '', file = out)
        else:
          print(" ", end = '', file = out)
        pixel = pixel + 1
        if pixel % glyph_w == 0:
          print('', file = out)
    x = x + glyph_w
    num = num + 1
  y = y + glyph_h

out.close()
