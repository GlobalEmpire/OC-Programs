from bisect import bisect_left
from joblib import Parallel, delayed
import numpy
from PIL import Image
from skimage import measure

# Zoom zoom! ;)

# Putpaltte.
aalette = [0, 0, 0, 0, 0, 64, 0, 0, 128, 0, 0, 192, 0, 0, 255, 0, 36, 0, 0, 36, 64, 0, 36, 128, 0, 36, 192, 0, 36, 255,
           0, 73, 0, 0, 73, 64, 0, 73, 128, 0, 73, 192, 0, 73, 255, 0, 109, 0, 0, 109, 64, 0, 109, 128, 0, 109, 192,
           0, 109, 255, 0, 146, 0, 0, 146, 64, 0, 146, 128, 0, 146, 192, 0, 146, 255, 0, 182, 0, 0, 182, 64, 0, 182,
           128, 0, 182, 192, 0, 182, 255, 0, 219, 0, 0, 219, 64, 0, 219, 128, 0, 219, 192, 0, 219, 255, 0, 255, 0, 0,
           255, 64, 0, 255, 128, 0, 255, 192, 0, 255, 255, 51, 0, 0, 51, 0, 64, 51, 0, 128, 51, 0, 192, 51, 0, 255,
           51, 36, 0, 51, 36, 64, 51, 36, 128, 51, 36, 192, 51, 36, 255, 51, 73, 0, 51, 73, 64, 51, 73, 128, 51, 73,
           192, 51, 73, 255, 51, 109, 0, 51, 109, 64, 51, 109, 128, 51, 109, 192, 51, 109, 255, 51, 146, 0, 51, 146,
           64, 51, 146, 128, 51, 146, 192, 51, 146, 255, 51, 182, 0, 51, 182, 64, 51, 182, 128, 51, 182, 192, 51, 182,
           255, 51, 219, 0, 51, 219, 64, 51, 219, 128, 51, 219, 192, 51, 219, 255, 51, 255, 0, 51, 255, 64, 51, 255,
           128, 51, 255, 192, 51, 255, 255, 102, 0, 0, 102, 0, 64, 102, 0, 128, 102, 0, 192, 102, 0, 255, 102, 36, 0,
           102, 36, 64, 102, 36, 128, 102, 36, 192, 102, 36, 255, 102, 73, 0, 102, 73, 64, 102, 73, 128, 102, 73, 192,
           102, 73, 255, 102, 109, 0, 102, 109, 64, 102, 109, 128, 102, 109, 192, 102, 109, 255, 102, 146, 0, 102, 146,
           64, 102, 146, 128, 102, 146, 192, 102, 146, 255, 102, 182, 0, 102, 182, 64, 102, 182, 128, 102, 182, 192,
           102, 182, 255, 102, 219, 0, 102, 219, 64, 102, 219, 128, 102, 219, 192, 102, 219, 255, 102, 255, 0, 102,
           255, 64, 102, 255, 128, 102, 255, 192, 102, 255, 255, 153, 0, 0, 153, 0, 64, 153, 0, 128, 153, 0, 192, 153,
           0, 255, 153, 36, 0, 153, 36, 64, 153, 36, 128, 153, 36, 192, 153, 36, 255, 153, 73, 0, 153, 73, 64, 153, 73,
           128, 153, 73, 192, 153, 73, 255, 153, 109, 0, 153, 109, 64, 153, 109, 128, 153, 109, 192, 153, 109, 255, 153,
           146, 0, 153, 146, 64, 153, 146, 128, 153, 146, 192, 153, 146, 255, 153, 182, 0, 153, 182, 64, 153, 182, 128,
           153, 182, 192, 153, 182, 255, 153, 219, 0, 153, 219, 64, 153, 219, 128, 153, 219, 192, 153, 219, 255, 153,
           255, 0, 153, 255, 64, 153, 255, 128, 153, 255, 192, 153, 255, 255, 204, 0, 0, 204, 0, 64, 204, 0, 128, 204,
           0, 192, 204, 0, 255, 204, 36, 0, 204, 36, 64, 204, 36, 128, 204, 36, 192, 204, 36, 255, 204, 73, 0, 204, 73,
           64, 204, 73, 128, 204, 73, 192, 204, 73, 255, 204, 109, 0, 204, 109, 64, 204, 109, 128, 204, 109, 192, 204,
           109, 255, 204, 146, 0, 204, 146, 64, 204, 146, 128, 204, 146, 192, 204, 146, 255, 204, 182, 0, 204, 182, 64,
           204, 182, 128, 204, 182, 192, 204, 182, 255, 204, 219, 0, 204, 219, 64, 204, 219, 128, 204, 219, 192, 204,
           219, 255, 204, 255, 0, 204, 255, 64, 204, 255, 128, 204, 255, 192, 204, 255, 255, 255, 0, 0, 255, 0, 64, 255,
           0, 128, 255, 0, 192, 255, 0, 255, 255, 36, 0, 255, 36, 64, 255, 36, 128, 255, 36, 192, 255, 36, 255, 255, 73,
           0, 255, 73, 64, 255, 73, 128, 255, 73, 192, 255, 73, 255, 255, 109, 0, 255, 109, 64, 255, 109, 128, 255, 109,
           192, 255, 109, 255, 255, 146, 0, 255, 146, 64, 255, 146, 128, 255, 146, 192, 255, 146, 255, 255, 182, 0, 255,
           182, 64, 255, 182, 128, 255, 182, 192, 255, 182, 255, 255, 219, 0, 255, 219, 64, 255, 219, 128, 255, 219,
           192,
           255, 219, 255, 255, 255, 0, 255, 255, 64, 255, 255, 128, 255, 255, 192, 255, 255, 255, 255, 255, 255, 255,
           255,
           255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
           255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]

palimage = Image.new('P', (16, 16))
palimage.putpalette(aalette)


def correcttonumpy(pilimage):
    return numpy.array(pilimage, dtype='uint8')


def correcttopil(numpyarray):
    return Image.fromarray(numpyarray.astype('uint8'))


def takeclosest(takecloselist, takecloseint):
    """
    Assumes myList is sorted. Returns closest value to myNumber.

    If two numbers are equally close, return the smallest number.
    """
    pos = bisect_left(takecloselist, takecloseint)
    if pos == 0:
        return takecloselist[0]
    if pos == len(takecloselist):
        return takecloselist[-1]
    before = takecloselist[pos - 1]
    after = takecloselist[pos]
    if after - takecloseint < takecloseint - before:
        return after
    else:
        return before


def quantizetopalette(silf, palette):
    """Convert an RGB or L mode image to use a given P image's palette."""

    silf.load()

    # use palette from reference image
    palette.load()
    if palette.mode != "P":
        raise ValueError("bad mode for palette image")
    if silf.mode != "RGB" and silf.mode != "L":
        raise ValueError(
            "only RGB or L mode images can be quantized to a palette"
        )
    im = silf.im.convert("P", 0, palette.im)
    im = im.convert("RGB", 0, palette.im)
    return silf._new(im)


def applypilpalette(pilimage):
    return quantizetopalette(pilimage, palimage)


def resizetosize(pilimage, maxwidth=None, maxheight=None):
    if maxwidth is None or maxheight is None:
        maxheight = 50
        maxwidth = 160
    width = pilimage.size[0]
    height = pilimage.size[1]
    ratio = max(width // maxwidth, height // maxheight)
    return pilimage.resize((width // ratio, height // ratio))


def createfillers(numpyarray):
    labelarray, count = measure.label(numpyarray, connectivity=None, return_num=True)
    print(f"Total Count: {count}")
    properties = measure.regionprops(labelarray)
    return properties
