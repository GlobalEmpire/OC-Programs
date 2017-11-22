# OCRC
OpenComputersRapidCRAM Technology [Video Streaming Like [ICE2](https://github.com/ChenThread/ice2)]
- Thanks to [gamax92](https://github.com/gamax92) for coding much of the lua script!

# WARNING
- This Streaming software is only to be
- **USED FOR EXPERINCED USERS**
- If you just started using OpenComputers:
- **ITS NOT RECOMMENDED TO USE THIS SOFTWARE.**
- **YOU HAVE BEEN WARNED.**

### Knowledge Requirements
- Able to use Command Prompt or Console Fluently
- 

Files:
- Main.py [Used For Streaming to files.]
- ImpageToPalatte [Convert Still images that are extracted to a textstream]
- constants [Well its just a really large constant. This constant is used when audio is being sent via dfpwm]
- client.lua [Client for the OC computers]

## Requirements
### ImpageToPalette.py
- Python 3.6.2 
- Linux Users: [Pillow-SIMD](https://github.com/uploadcare/pillow-simd)
- Windows users : Install this [Pillow-SIMD](https://www.lfd.uci.edu/~gohlke/pythonlibs/#pillow-simd) instead
- [tqdm](https://pypi.python.org/pypi/tqdm) aka Progress in Arabic
### Main.py
- zlib (Should Have come packaged with your Python install)
- socket (Should Have come packaged with your Python install)

### Usage
1. Change Directory so that your directory is in `imagesequence`
2. (If not installed) install FFmpeg. make sure it works for you.
3. Move your video file to imagesequence folder.
4. [`ffmpeg -i (Input file) Out%03d.png`] Run this command where Input file is your video file.
5. Remove the video file.
6. run ImpageToPalette.py
7. By Default your FPS should be 30 for your video. if not, please check with your local video software info page...
- VLC: Tools > Media Infomation > Codec > Frame Rate [Round to nearest number if its decimal.]
- Windows Media Player: *Why are you still using it... get VLC or something else.*
- MPC-HC: Rendering Settings > Display Stats > Frame Rate [Round to nearest number if its decimal.]
- PotPlayer: Tab Key > Video Codec > Input > FPS [Round to nearest number if its decimal.]
- XBMC(Kodi): O Key
- GOMPlayer: Someone find it out for me. thanks.
8. [Minecraft] On your computer, get a Tier 3 GPU, Internet Card and a Tape Drive.
9. wget `client.lua` file.
10. start the server(Main.py)
11. If your computer is on the same network as where you ran the server, check the IP address that is printed on the server. Else, google `portfowarding`.
12. run the client.lua. There is a small help section : [IP] [Port (Always 25561 unless you changed it.)] [false]
13. Enjoy the slideshow.