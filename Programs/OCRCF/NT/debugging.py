import functools
import time
import sys
from tkinter import Tk, Canvas, PhotoImage, mainloop


def timeit(func):
    @functools.wraps(func)
    def newfunc(*args, **kwargs):
        startTime = time.time()
        func(*args, **kwargs)
        elapsedTime = time.time() - startTime
        print('function [{}] finished in {} ms'.format(
            func.__name__, int(elapsedTime * 1000)))

    return newfunc


class tkinterrenderer:
    def __init__(self):
        self.w, self.h = 200, 200
        self.windows = Tk()
        self.windows.title("SOMEONE ELSE")
        self.canvas = Canvas(self.windows, width=self.w, height=self.h, bg="#000000")
        self.canvas.pack()
        self.img = PhotoImage(width=self.w, height=self.h)
        self.canvas.create_image((self.w, self.h), image=self.img, state="normal")

    def pixel(self, color, x, y, ):
        self.img.put(color, to=(int(x), int(y)))
        self.refresh()

    def fill(self, color, x, y, w, h):
        self.img.put(color, to=(x, x + w, y, y + h))
        self.refresh()

    def refresh(self):
        self.windows.update_idletasks()
        self.windows.update()
        self.canvas.update_idletasks()
        self.canvas.update()