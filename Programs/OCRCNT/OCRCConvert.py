import os
import subprocess
import sys
import zipfile
import Utils
import traceback
import imageio
import imageiolib

print("Checking and Installing \"colorama\".")
try:
    from colorama import Fore, Back, Style
    import colorama

    colorama.init(True)
except ImportError:
    import pip

    pip.main(['install', 'colorama'])

    from colorama import Fore, Back, Style
    import colorama

    colorama.init(True)
print("Done!")


def main():
    try:
        print("Checking/Installing for FFmpeg...")
        imageio.plugins.ffmpeg.download()
        print("Gonna need to setup a few Config First.")
        print("--- Optimise ---")
        print("There are 2 types:\n"
              "Level [1] [Default]: Uses imageio's subrectagles to optimise the video. great for a still or slow "
              "image.\n "
              "Level [2] [Gifsicle]: Uses Gifsicle to compress the images. Smaller Size.")
        try:
            gifsicleoptimise = int(input('Optimization method >:'))
        except ValueError:
            gifsicleoptimise = 1
            print("Invalid value. Using Defaults.")
        print("--- Delete Video after done? ---")
        print("[Y]es, [N]o (Default)")
        if 'y' in input('Delete Inputs >:').lower():
            deleteinputs = True
        else:
            deleteinputs = False
        print("--- Working! ---")
        try:
            x = os.listdir(os.path.join(os.getcwd(), 'videoinput'))[0]
        except IndexError:
            print("No Videos in videoinput folder!")
            sys.exit()
        except FileNotFoundError:
            print("Did you delete the videoinput folder? You monster!")
            sys.exit()
        if x == 'gitpls':
            print("Be sure to delete the \"gitpls\" file!")
            sys.exit()
        print(f"Using: {x}\n"
              f"[If you want to select the another video. Close now and delete this video file]")
        print("Progressing with Milla...")
        readerobject, fps, frames, name = imageiolib.multiread(os.path.join(os.getcwd(), 'videoinput', x))
        print(f"FPS: {fps} | Total Frames: {frames}")
        imageiolib.MultiWriteGifWrapper(readerobject, os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"),
                                        True if gifsicleoptimise is 1 else False)
        if gifsicleoptimise == 2:
            subprocess.call(
                [os.path.join(os.getcwd(), 'deps', 'gifsicle.exe'),
                 '--optimize=3',
                 os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"),
                 '-o', os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif")])
        print("Adding Music [Generating music DFPWM] [May take a while depending on the kind of audio file.]")
        subprocess.call(['ffmpeg', '-i', os.path.join(os.getcwd(), 'videoinput', x),
                         os.path.join(os.getcwd(), 'workinginput', f'{name[0]}.wav')])
        subprocess.call(['java', '-jar', os.path.join(os.getcwd(), 'deps', 'LionRay.jar'),
                         os.path.join(os.getcwd(), 'workinginput', f'{name[0]}.wav'),
                         os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.dfpwm")])
        print("Creating Portable Zip...")
        azip = zipfile.ZipFile(os.path.join(os.getcwd(), 'output', f"{name[0]}.zip"),
                               mode='x', compression=zipfile.ZIP_DEFLATED)
        azip.write(os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"), f"{name[0]}.gif")
        azip.write(os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.dfpwm"), f"{name[0]}.dfpwm")
        print("Cleanup")
        if deleteinputs:
            #  os.remove(os.path.join(os.getcwd(), 'videoinput', x))
            print("deleteing inputs...")
        for x in os.listdir('workinginput'):
            os.remove(os.path.join(os.getcwd(), 'workinginput', x))
        print("Finished!")
    except Exception as e:
        print(f"\n\n---------------------- {Utils.crashrand()} ----------------------")
        print("!!! ERROR FROM OCRCConvert !!!\n"
              "REPORT THIS VIDEO FILE TO GITHUB!\n"
              "https://github.com/GlobalEmpire/OC-Programs/issues\n"
              f"Video Link or file: {x} [Upload it to dropbox or a file hosting service. NOT YOUTUBE.]\n"
              f"Traceback:\n")
        for line in traceback.format_tb(e.__traceback__):
            print(line)
        print(f"Report The Error Below:\n\"{e}\"\n")
        print("-----------------------------------------------------------------")


if __name__ == '__main__':
    main()
