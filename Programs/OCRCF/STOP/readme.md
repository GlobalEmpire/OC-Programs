# STOP
```
/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
```
STOP Engine Quick Usage Manual:  

`java -jar STOP.jar`

Hosts STOP/3 server on port 1291  

Expects files:  
out.ass (blank file is valid, parser is almost non-existent)  
audio.dfpwm (`java -jar LionRay.jar audio.wav audio.dfpwm`)  
frames/*.png (`ffmpeg -i input.mkv -s 160x100 -r 20 -f image2 frames/%5d.png`)  

If `iHateDisk` flag is on in `Main.java`, expects `oframes` directory to write to.

Configuration is non-existent. Any configuration must be done by examining code.

Good luck!

\- 20kdc