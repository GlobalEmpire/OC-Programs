"""
imageio lib
"""
import os
import sys
import imageio
import tqdm
import traceback

import Utils


def multiread(video):
    reader = imageio.get_reader(video, mode='I')
    fps = reader.get_meta_data()['fps']
    frames = reader.get_meta_data()['nframes']
    # Slight hack. Because WE NEED the filename but,
    # imageio decides its a very good idea to make it private.
    # noinspection PyProtectedMember
    name = os.path.split(reader._filename)[-1].split('.')[:-1]
    return reader, fps, frames, name


def MultiWriteGifWrapper(readerobject, fp, useinternal=True):
    wrapperobject = MultiWriteGif(fp,
                                  fps=readerobject.get_meta_data()['fps'], optimise=useinternal)

    with tqdm.tqdm(desc="Images Extracted & Converted", total=readerobject.get_length(),
                   unit='frames') as bar:
        try:
            for index, image in enumerate(readerobject):
                image = Utils.resizetosize(Utils.correcttopil(image))
                image = Utils.correcttonumpy(Utils.applypilpalette(image))
                wrapperobject.adddata(image)
                bar.update(1)
        except RuntimeError as e:
            if 'frame' in e:
                print("WARN: Frame Error in reading Video. Silently discarding.")
                wrapperobject.finish()
            else:
                print(f"\n\n---------------------- {Utils.crashrand()} ----------------------")
                print("!!! RUNTIME ERROR FROM IMAGEIO !!!\n"
                      "REPORT THIS VIDEO FILE TO GITHUB!\n"
                      "https://github.com/GlobalEmpire/OC-Programs/issues\n"
                      f"Video Link or file: {fp} [Upload it to dropbox or a file hosting service. NOT YOUTUBE.]\n"
                      f"Report The Error Below:\n\"{e}\"\n"
                      )
                print("-----------------------------------------------------------------")
                sys.exit(400)
    wrapperobject.finish()


class MultiWriteGif:

    def __init__(self, fp, fps, optimise=True):
        print(fp)
        self.writer = imageio.get_writer(fp, fps=fps, subrectangles=optimise)

    def adddata(self, imageioframe):
        try:
            self.writer.append_data(imageioframe)
        except ValueError as e:
            self.finish()
            return e
        return 'OK'

    def finish(self):
        self.writer.close()
        return 'OK'
