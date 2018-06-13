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
        gifsicleoptimise = 2
        print("--- Delete Video after done? ---")
        print("[Y]es, [N]o (Default)")
        if 'y' in input('Delete Inputs >:').lower():
            deleteinputs = True
        else:
            deleteinputs = False
        print("--- Working! ---")
        try:
            videos = os.listdir(os.path.join(os.getcwd(), 'videoinput'))
        except IndexError:
            print("No Videos in videoinput folder!")
            sys.exit()
        except FileNotFoundError:
            print("Did you delete the videoinput folder? You monster!")
            sys.exit()
        if 'gitpls' in videos:
            print("Be sure to delete the \"gitpls\" file!")
            sys.exit()
        for x in videos:
            a = os.path.join(os.getcwd(), 'videoinput',x)
            print(f"Prcoessing: {x}")
            subprocess.call(['ffmpeg', '-i', a, '-c', 'copy', '-c', 'copy', os.path.join(os.getcwd(), 'videoinput', f"active{x}")])
            readerobject, fps, frames, name = imageiolib.multiread(os.path.join(os.getcwd(), 'videoinput', f"active{x}"))
            imageiolib.MultiWriteGifWrapper(readerobject, os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"),
                                            True if gifsicleoptimise is 1 else False)
            subprocess.call([os.path.join(os.getcwd(), 'deps', 'gifsicle.exe'), '--optimize=3',
                             os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"),
                             '-o', os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif")])
            print("Generating music DFPWM file. [May take a while depending on the kind of audio file.]")
            subprocess.call(['ffmpeg', '-i', os.path.join(os.getcwd(), 'videoinput', f"active{x}"),
                             os.path.join(os.getcwd(), 'workinginput', f'{name[0]}.wav')], stderr=subprocess.DEVNULL)
            subprocess.call(['java', '-jar', os.path.join(os.getcwd(), 'deps', 'LionRay.jar'),
                             os.path.join(os.getcwd(), 'workinginput', f'{name[0]}.wav'),
                             os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.dfpwm")])
            print("create info.txt")
            with open(os.path.join(os.getcwd(), 'workinginput', f"info.txt"), 'w+') as info:
                info.write(str(fps))
            print("Creating Portable Zip...")
            azip = zipfile.ZipFile(os.path.join(os.getcwd(), 'output', f"{name[0]}.zip"),
                                   mode='x', compression=zipfile.ZIP_DEFLATED)
            azip.write(os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.gif"), f"{name[0]}.gif")
            azip.write(os.path.join(os.getcwd(), 'workinginput', f"{name[0]}.dfpwm"), f"{name[0]}.dfpwm")
            azip.write(os.path.join(os.getcwd(), 'workinginput', "info.txt"), "info.txt")
            print("Cleaning up...")
            if deleteinputs:
                os.remove(os.path.join(os.getcwd(), 'videoinput', f"active{x}"))
                print("deleting inputs...")
            for workingfile in os.listdir('workinginput'):
                os.remove(os.path.join(os.getcwd(), 'workinginput', workingfile))
            print("")
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
