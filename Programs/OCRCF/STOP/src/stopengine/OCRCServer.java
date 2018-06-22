/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package stopengine;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;
import java.util.LinkedList;

public class OCRCServer extends Thread {
    public byte[] packedAudio;
    public STOP stopCore;
    public Socket socketCore;
    public OCRCServer(byte[] au, STOP stop, Socket sock) {
        packedAudio = au;
        stopCore = stop;
        socketCore = sock;
    }

    @Override
    public void run() {
        try {
            DataOutputStream dos = new DataOutputStream(socketCore.getOutputStream());
            dos.writeBytes("STOP/3");
            dos.write(0);
            InputStream ins = socketCore.getInputStream();
            while (true) {
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                while (true) {
                    int b = ins.read();
                    if (b == -1)
                        throw new IOException("OUTATIME");
                    if (b == 0)
                        break;
                    baos.write(b);
                }
                String cmd = baos.toString("UTF-8");
                System.out.println(cmd);
                if (cmd.equals("AUDIO")) {
                    dos.writeInt(packedAudio.length);
                    dos.flush();
                } else if (cmd.equals("SEND")) {
                    dos.write(packedAudio);
                    dos.flush();
                } else if (cmd.equals("PACK")) {
                    int fIDX = 0;
                    STOP.STOPFrame currentFrame = stopCore.firstFrame;
                    while (currentFrame != null) {
                        // 6000 bytes/s / 20FPS = 300
                        currentFrame.compileFrame(dos, fIDX * 300);
                        dos.flush();
                        if (currentFrame.terminate)
                            break;
                        STOP.STOPFrame nextFrame = currentFrame.nextFrame.get();
                        if (nextFrame != null) {
                            System.out.println("Frame Sent: " + fIDX);
                            currentFrame = nextFrame;
                            fIDX++;
                        }
                    }
                }
            }
        } catch (Exception e) {
            try {
                socketCore.close();
            } catch (Exception e2) {
            }
            e.printStackTrace();
        }
    }
}
