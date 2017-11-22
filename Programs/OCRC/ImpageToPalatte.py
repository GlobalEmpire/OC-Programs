import os
from PIL import Image
import re
from tqdm import tqdm
import sys
from itertools import islice

def get_line():
    with open('your file') as file:
        for i in file:
            yield i


def atoi(text):
    return int(text) if text.isdigit() else text


def natural_keys(text):
    return [atoi(c) for c in re.split('(\d+)', text)]

time = input("FPS >:")
if skiparray in ['y', 'yes', 'true']:
    sortedlist = sorted(os.listdir(os.path.join("..", 'imagesequence')), key=natural_keys)
    ab = Image.open(os.path.join("..", 'imagesequence', sortedlist[0]))
    print(ab.convert("P", palette=Image.WEB).getpalette())
    scale = max(ab.height / 50, ab.width / 160)
    print(scale)
    print(f"Width: {ab.width//scale} Height: {ab.height//scale}")
    sys.exit(0)
else:
    sortedlist = sorted(os.listdir(os.path.join("..", 'imagesequence')), key=natural_keys)
    ab = Image.open(os.path.join("..", 'imagesequence', sortedlist[0]))
    ab = ab.convert("P", palette=Image.WEB, colors=240)
    scale = max(ab.height / 50, ab.width / 160)
    palette = Image.open("OCT3Palette.png")
    palettelist = [palette.getpalette()[x:x + 3] for x in range(0, len(palette.getpalette()), 3)]
    ab.close()
    hexpalettelist = []
    for x in palettelist:
        r, g, b = x[0], x[1], x[2]
        hexpalettelist.append("0x{:02x}{:02x}{:02x}".format(r, g, b))
    print(f"Resize to: {(int(ab.width//scale), int(ab.height//scale))}")
print("Prcoessing. Please Have Patience! a 5min 30fps Video Takes ~ about 2 minutes.")
with open("imagearray.txt", "a+") as arrayfile:
    arrayfile.write(f"""{str(hexpalettelist).replace("[","").replace("]","").replace("'","").replace(" ","")}\n""")
    arrayfile.write(f"{int(ab.width//scale)},{int(ab.height//scale)},{int(time)}\n")
    with tqdm(total=len(os.listdir("..\imagesequence")), unit="file") as pbar:
        for file in sorted(os.listdir("..\imagesequence"), key=natural_keys):
            im = Image.open(os.path.join("..", 'imagesequence', file))
            im = im.resize((int(im.width // scale), int(im.height // scale)))
            im = im.quantize(palette=palette)
            imlist = list(im.getdata())
            # Account for lua arrays which DO NOT START AT 0.
            # REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
            imlist = [x + 1 for x in imlist]
            imlist = map(str, imlist)
            imlist = [ab.zfill(3) for ab in imlist]
            try:
                arrayfile.write(f"""{'|'.join(imlist).replace(" ","")}\n""")
            except FileNotFoundError as e:
                print(f"404 File not Found: {e}")
            pbar.update(1)
print(f"""Done processing {len(os.listdir(os.path.join("..", 'imagesequence')))} files.""")
