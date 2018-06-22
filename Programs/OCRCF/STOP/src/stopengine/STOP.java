/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package stopengine;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.concurrent.atomic.AtomicReference;

public class STOP {
    public BufferedImage worldState = new BufferedImage(160, 50, BufferedImage.TYPE_INT_RGB);

    public STOPFrame firstFrame = new STOPFrame();
    public STOPFrame currentFrame = firstFrame;
    public boolean streamingMode;

    public void introducePacket(STOPPacket sp) {
        Graphics g = worldState.getGraphics();
        g.setColor(new Color(OCPal.ocPal[sp.bgCol]));
        for (STOPSubpacket ssp : sp.subpackets) {
            int ew = ssp.w;
            int eh = ssp.h;
            g.fillRect(ssp.x, ssp.y, ew, eh);
        }
    }

    public double introducePacketsFromSPList(double timeRemaining, BufferedImage coverage, LinkedList<STOPSubpacket> ll, String tx, boolean terminator) {
        Graphics g = coverage.getGraphics();
        g.setColor(Color.white);
        LinkedList<STOPPacket> workingPackets = new LinkedList<STOPPacket>();
        HashMap<Integer, STOPPacket> knownRGBs = new HashMap<Integer, STOPPacket>();
        for (STOPSubpacket sp : ll) {
            double cost = sp.canBeSet() ? 1d / 256d : 1d / 128d;
            boolean hasBG = true;
            if (!knownRGBs.containsKey(sp.bgCol)) {
                hasBG = false;
                cost += 1d / 128d;
            }
            if (cost <= timeRemaining) {
                if (sp.isValidGivenCoverage(coverage)) {
                    g.fillRect(sp.x, sp.y, sp.w, sp.h);
                    if (!hasBG) {
                        STOPPacket p;
                        knownRGBs.put(sp.bgCol, p = new STOPPacket(sp.bgCol));
                        workingPackets.add(p);
                    }
                    knownRGBs.get(sp.bgCol).subpackets.add(sp);
                    timeRemaining -= cost;
                }
            }
        }

        // Finish up the frame.

        for (STOPPacket p : workingPackets)
            introducePacket(p);

        STOPFrame sf = new STOPFrame();
        sf.text = tx;
        sf.packets = workingPackets;
        sf.terminate = terminator;
        currentFrame.nextFrame.set(sf);
        currentFrame = sf;

        if (streamingMode)
            firstFrame = sf;

        return timeRemaining;
    }

    public static class STOPFrame {
        public LinkedList<STOPPacket> packets = new LinkedList<STOPPacket>();
        public AtomicReference<STOPFrame> nextFrame = new AtomicReference<STOPFrame>();
        public boolean terminate;
        public String text = "";
        public STOPFrame() {
            packets.add(new STOPPacket(0));
        }

        public void compileFrame(OutputStream os, int tapeTime) throws IOException {
            DataOutputStream dos = new DataOutputStream(os);
            if (tapeTime < 0)
                throw new IOException("Tape time < 0!");
            dos.writeInt(tapeTime);
            if (packets.size() >= 65536)
                throw new IOException("Over 65536 packets. This should be impossible.");
            dos.write(text.getBytes("UTF-8"));
            dos.write(0);
            dos.writeShort(packets.size());
            for (STOPPacket sp : packets) {
                if (sp.subpackets.size() >= 65536)
                    throw new IOException("Over 65536 subpackets. This should be impossible.");
                dos.write(sp.bgCol);
                dos.writeShort(sp.subpackets.size());
                for (STOPSubpacket ssp : sp.subpackets) {
                    dos.write(ssp.x);
                    dos.write(ssp.y);
                    dos.write(ssp.w);
                    dos.write(ssp.h);
                    dos.write(ssp.canBeSet() ? 1 : 0);
                }
            }
            dos.write(terminate ? 1 : 0);
        }
    }

    public static class STOPPacket {
        public int bgCol;
        public LinkedList<STOPSubpacket> subpackets = new LinkedList<STOPSubpacket>();

        public STOPPacket(int bgCol) {
            this.bgCol = bgCol;
        }
    }
    public static class STOPSubpacket {
        public int bgCol;
        public int x, y, w, h, score;

        public STOPSubpacket(int tx, int ty, int tw, int th, int tb, int scor) {
            x = tx;
            y = ty;
            w = tw;
            h = th;
            bgCol = tb;
            score = scor;
        }

        public STOPSubpacket(STOPSubpacket lastPacket) {
            x = lastPacket.x;
            y = lastPacket.y;
            w = lastPacket.w;
            h = lastPacket.h;
            bgCol = lastPacket.bgCol;
            score = lastPacket.score;
        }

        public boolean isValidGivenCoverage(BufferedImage coverage) {
            for (int i = 0; i < w; i++)
                for (int j = 0; j < h; j++)
                    if ((coverage.getRGB(x + i, y + j) & 0xFFFFFF) != 0)
                        return false;
            return true;
        }

        public boolean canBeSet() {
            return h == 1;
        }
    }
}
