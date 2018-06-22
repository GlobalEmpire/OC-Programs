/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package stopengine;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedList;

/**
 * The STOP! Engine
 * Created a few days before the 22nd of June 2018
 */
public class Main {
    public static void main(String[] args) throws IOException, InterruptedException {
        ASS a = new ASS();
        a.load(new FileInputStream("out.ass"));

        JFrame debugMon = new JFrame("STOP!");
        JPanel panel = new JPanel();

        boolean resultMode = false;
        boolean iHateDisk = false;

        if (!resultMode) {
            panel.setPreferredSize(new Dimension(640, 332));

            debugMon.add(panel, BorderLayout.CENTER);
            debugMon.pack();
            debugMon.setLocationRelativeTo(null);
            debugMon.setResizable(false);
            debugMon.setVisible(true);
        }

        final STOP s = new STOP();

        new Thread() {
            @Override
            public void run() {
                try {
                    ServerSocket ss = new ServerSocket(1291);
                    FileInputStream fis = new FileInputStream("audio.dfpwm");
                    byte[] audio = new byte[fis.available()];
                    if (audio.length != fis.read(audio))
                        throw new IOException("Oddity with audio");
                    fis.close();
                    System.out.println("STOP! Engine listening on port 1291 for Ristelle's cli.lua connection");
                    while (true) {
                        Socket sock = ss.accept();
                        new OCRCServer(audio, s, sock).start();
                    }
                } catch (IOException ioe) {
                    ioe.printStackTrace();
                }
            }
        }.start();

        BufferedImage bi2 = new BufferedImage(160, 50, BufferedImage.TYPE_INT_RGB);
        Graphics g2 = bi2.getGraphics();
        int i = 1;
        double utilizationPerFrame = 0.95;
        while (true) {
            String tx = a.advance();
            a.assTime++;

            String n = Integer.toString(i);
            while (n.length() < 5)
                n = "0" + n;
            BufferedImage bi;
            try {
                bi = ImageIO.read(new File("frames/" + n + ".png"));
            } catch (Exception e) {
                break;
            }
            g2.drawImage(bi, 0, 0, 160, 50, null);
            final LinkedList<STOP.STOPSubpacket> spList = new LinkedList<STOP.STOPSubpacket>();
            prepareSPList(s.worldState, bi2, spList);
            Collections.sort(spList, new Comparator<STOP.STOPSubpacket>() {
                @Override
                public int compare(STOP.STOPSubpacket stopSubpacket, STOP.STOPSubpacket t1) {
                    int area1 = stopSubpacket.score;
                    int area2 = t1.score;
                    if (area1 < area2)
                        return 1;
                    if (area1 > area2)
                        return -1;
                    return 0;
                }
            });
            BufferedImage coverage = new BufferedImage(160, 50, BufferedImage.TYPE_BYTE_BINARY);
            double timeRemaining = s.introducePacketsFromSPList(utilizationPerFrame, coverage, spList, tx, false);
            System.out.println(i + ";" + spList.size() + ";" + timeRemaining);
            if (!resultMode) {
                Graphics g = panel.getGraphics();
                g.drawImage(bi, 0, 0, 160, 100, null);
                g.drawImage(coverage, 0, 100, 160, 100, null);
                g.drawImage(s.worldState, 0, 200, 160, 100, null);
                g.setColor(Color.black);
                g.fillRect(0, 300, 640, 50);
                g.setColor(Color.white);
                g.drawString(tx, 8, 316);
            }
            if (iHateDisk)
                ImageIO.write(s.worldState, "PNG", new File("oframes/" + n + ".png"));
            i++;
        }
        BufferedImage coverage = new BufferedImage(160, 50, BufferedImage.TYPE_BYTE_BINARY);
        s.introducePacketsFromSPList(utilizationPerFrame, coverage, new LinkedList<STOP.STOPSubpacket>(), "", true);
    }

    private static void prepareSPList(BufferedImage worldState, BufferedImage bi, LinkedList<STOP.STOPSubpacket> sp) {
        int w = worldState.getWidth();
        int h = worldState.getHeight();
        int[] massDataWS = new int[w * h];
        int[] massDataBI = new int[w * h];
        bi.getRGB(0, 0, w, h, massDataBI, 0, w);
        worldState.getRGB(0, 0, w, h, massDataWS, 0, w);
        int idx = 0;
        for (int j = 0; j < worldState.getHeight(); j++) {
            STOP.STOPSubpacket lastPacket = null;
            for (int i = 0; i < worldState.getWidth(); i++) {
                int resPal = OCPal.find(massDataBI[idx]);
                int resRGB = OCPal.ocPal[resPal] | 0xFF000000;
                // Can this just be appended to the last packet?
                if (lastPacket != null) {
                    if (lastPacket.bgCol == resPal) {
                        lastPacket.w++;
                        if (massDataWS[idx] != resRGB)
                            lastPacket.score += 2;
                    } else {
                        finalizeSP(massDataWS, massDataBI, w, h, lastPacket, sp);
                        lastPacket = null;
                    }
                }
                if (lastPacket == null)
                    if (massDataWS[idx] != resRGB)
                        sp.add(lastPacket = new STOP.STOPSubpacket(i, j, 1, 1, resPal, 2));
                idx++;
            }
            if (lastPacket != null)
                finalizeSP(massDataWS, massDataBI, w, h, lastPacket, sp);
        }
    }

    private static void finalizeSP(int[] massDataWS, int[] massDataBI, int w, int h, STOP.STOPSubpacket lastPacket, LinkedList<STOP.STOPSubpacket> sps) {
        for (int i = lastPacket.y + 1; i < h; i++) {
            int potentialScoreUpdate = 0;
            for (int j = 0; j < lastPacket.w; j++) {
                int widx = (i * w) + j + lastPacket.x;
                int resPal = OCPal.find(massDataBI[widx]);
                int resRGB = OCPal.ocPal[resPal] | 0xFF000000;
                if (massDataWS[widx] != resRGB)
                    potentialScoreUpdate++;
                if (resPal != lastPacket.bgCol)
                    return;
            }
            if (lastPacket.h == 1) {
                // Backup of the old packet. Might be more efficient.
                sps.add(new STOP.STOPSubpacket(lastPacket));
                lastPacket.score /= 2;
            }
            lastPacket.score += potentialScoreUpdate;
            lastPacket.h++;
        }
    }
}
