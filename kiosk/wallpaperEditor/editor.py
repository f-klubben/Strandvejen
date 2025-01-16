from PIL import Image, ImageDraw, ImageFont
import textwrap
from sys import argv

def merge(im1:Image.Image, im2:Image.Image):
    width1, height1 = im1.size
    width2, height2 = im2.size
    center_x, center_y = int(width1/2), int(height1/2)
    coords = center_x - int(width2/2), center_y - int(height2/2)
    im1.paste(im2, coords)


main = Image. new("RGB", (1920, 1080))

img = Image.open(argv[1])
draw = ImageDraw.Draw(main)
header_font = ImageFont.load_default(40)
text_font = ImageFont.load_default(30)

merge(main, img)

box = (15, 15, 515, 615)
draw.rectangle(box, 'black')
draw.line(((box[0], box[1]), (box[0], box[3])), fill="white")
draw.line(((box[0], box[3]), (box[2], box[3])), fill="white")
draw.line(((box[2], box[3]), (box[2], box[1])), fill="white")
draw.line(((box[2], box[1]), (box[0], box[1])), fill="white")

y = 20
draw.text((20, y), argv[2], (255,255,255), font=header_font)
with open(argv[3], "r") as file:
    for line in file.read().split("\n"):
        for wrapped in textwrap.wrap(line, 30):
            y+=40
            draw.text((20, y), wrapped, (200,200,200), font=text_font)

main.save(argv[4])


