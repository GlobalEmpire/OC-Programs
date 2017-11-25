import ProcessImage
import ffmpy
import os
import subprocess


# ffmpeg -i video.avi -vn soundfile.wav
def generate(file, fps):
    inputitem = os.listdir("input")[0]
    ffmpy.FFmpeg(inputs={f'{os.path.join("input",inputitem)}': None},
                 outputs={f"{os.path.join('images','%03d.jpg')}": f"-vf fps={fps}",
                          f"{os.path.join('audio',f'{inputitem}.wav')}": None}).run()


def lionray(file):
    subprocess.call(['java', '-jar', 'deps\LionRay.jar', file])


filein = input("File Input (Relative to this script)>:")
fps = int(input("Input Image FPS Here >:"))
generate(filein, fps)
lionray(os.path.join('audio', f'{filein}.wav'))
ProcessImage.execute(fps)
