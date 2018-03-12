from PIL import PngImagePlugin
import numpy
from bisect import bisect_left
from skimage import measure

# These are the values in int for it to be clamped.
red = [0, 51, 102, 153, 204, 255]
green = [0, 36, 73, 109, 146, 182, 219, 255]
blue = [0, 64, 128, 192, 255]
rangefix = [x for x in range(0, 256)]
store = []


def clamp(x):
    """
    Modified Clamp that uses takeClosest.
    :param x:
    :return:
    """
    return takeclosest(rangefix, x)


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


def rgb2hex(r, g=None, b=None):
    if isinstance(type(r), type(list)) and g is None and b is None:
        r, g, b = r
    return "#{0:02x}{1:02x}{2:02x}".format(clamp(r), clamp(g), clamp(b))


def applyrgbhex(array, hexify=True):
    returnlist = []
    if isinstance(type(array), type(PngImagePlugin.PngImageFile)):
        array = numpy.array(array)
    for yaxis in array.tolist():
        yaxisreturn = []
        for pixel in yaxis:
            if hexify:
                # This Is correct but pycharm thinks it's not...
                # noinspection PyTypeChecker
                yaxisreturn.append(rgb2hex(colour240converter(pixel)))
            else:
                yaxisreturn.append(colour240converter(pixel))
        returnlist.append(yaxisreturn)
    return returnlist


def resizetosize(pilimage, maxwidth=None, maxheight=None):
    if maxwidth is None or maxheight is None:
        maxheight = 50
        maxwidth = 160
    width = pilimage.size[0]
    height = pilimage.size[1]
    ratio = max(width // maxwidth, height // maxheight)
    return pilimage.resize((width // ratio, height // ratio))


def createfillers(numpyarray):
    if isinstance(numpyarray, list):
        print("Correcting List!")
        numpyarray = numpy.array(numpyarray)
    labelarray, count = measure.label(numpyarray, connectivity=None, return_num=True)
    print(f"Total Count: {count}")
    properties = measure.regionprops(labelarray)
    return properties


def colour240converter(colorlist):
    r, g, b = takeclosest(red, colorlist[0]), takeclosest(green, colorlist[1]), takeclosest(blue, colorlist[2])
    return r, g, b


def listconcator(rgbarray):
    returnstring = ''
    for x in rgbarray:
        print(x)
        line = '|'.join(x)
        returnstring += line + '\n'
    return returnstring
