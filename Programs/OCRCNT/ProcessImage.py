import os
import numpy
from skimage import measure
import Utils
from PIL import Image
from tqdm import tqdm

"""
logger = logging.getLogger("")
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())
logger.addHandler(logging.FileHandler("debuglog.txt"))
"""
palette = Image.open("palette.png")
tests = ['abysstest1.png', 'abysstest2.png', 'gekijoutest.png', 'vesperialogo.png']


def processimage(file, imagescale):
    im = Image.open(file)
    im = im.resize((int(im.width // imagescale), int(im.height // imagescale)))
    im = im.quantize(palette=palette)
    imarray = numpy.array(im)
    generatefill(imarray)


def generatefill(originalarray: numpy.array):
    labeled = measure.label(originalarray, background=False, connectivity=2)
    labeledsortbysize = sorted(measure.regionprops(labeled, cache=True), key=lambda pixc: pixc.area, reverse=True)
    # Restrict to 170 max.
    with open("Instructions.txt", "a+") as f:
        for x in labeledsortbysize[:75]:
            f.write(f"F{str(x.bbox[0]).zfill(3)}{str(x.bbox[1]).zfill(3)}{str(x.bbox[2]-x.bbox[0]).zfill(3)}"
                    f"{str(x.bbox[3]-x.bbox[1]).zfill(3)}"
                    f"{str(originalarray[x.bbox[0],x.bbox[1]]).zfill(3)}&")
        for x in labeledsortbysize[-75:]:
            f.write(f"F{str(x.bbox[0]).zfill(3)}{str(x.bbox[1]).zfill(3)}{str(x.bbox[2]-x.bbox[0]).zfill(3)}"
                    f"{str(x.bbox[3]-x.bbox[1]).zfill(3)}"
                    f"{str(originalarray[x.bbox[0],x.bbox[1]]).zfill(3)}&")
        f.write("\n")
    return originalarray

def palettedata():
    palettelist = [palette.getpalette()[x:x + 3] for x in range(0, len(palette.getpalette()), 3)]
    hexpalettelist = []
    for x in palettelist:
        r, g, b = x[0], x[1], x[2]
        hexpalettelist.append("0x{:02x}{:02x}{:02x}".format(r, g, b))
    return hexpalettelist


def execute(fps=None):
    firstimg = os.listdir(os.path.join("imageseq"))[0]
    scaleimg = Image.open(os.path.join("imageseq", firstimg))
    scale = max(scaleimg.height / 50, scaleimg.width / 160)
    print(f"Scale: {scale} || W/H : {scaleimg.width//scale}/{scaleimg.height//scale}")
    hexpalettelist = palettedata()
    if fps is None:
        print("FPS not set!")
        fps = input("FPS? >:")
    else:
        fps = fps
    with open("Instructions.txt", "w+") as i:
        i.write(f"""{str(hexpalettelist).replace("[","").replace("]","").replace("'","").replace(" ","")}\n""")
        i.write(f"{scaleimg.width//scale},{scaleimg.height//scale},{fps}\n")
    with tqdm(total=len(os.listdir(os.path.join("imageseq")))) as pbar:
        for files in sorted(os.listdir(os.path.join("imageseq")), key=Utils.natural_keys):
            processimage(os.path.join("imageseq", files), scale)
            pbar.update(1)


if __name__ == "__main__":
    execute()
else:
    pass
