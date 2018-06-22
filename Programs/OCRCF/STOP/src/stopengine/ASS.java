/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package stopengine;

import java.io.*;
import java.util.LinkedList;

/*
 * Look, it's just the name of the format.
 * NOT MY FAULT. - 20kdc
 */
public class ASS {
    public int assTime = 0;
    public LinkedList<Runnable> assEvents = new LinkedList<Runnable>();
    // FIFO, in a way
    public LinkedList<String> assLines = new LinkedList<String>();

    public void load(InputStream fileInputStream) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(fileInputStream, "UTF-8"));
        while (br.ready()) {
            String l = br.readLine();
            if (l.startsWith("Dialogue: ")) {
                String[] split = l.split(",");
                final int ts1 = dets(split[1]);
                final int ts2 = dets(split[2]);
                String group3 = l;
                for (int i = 0; i < 9; i++)
                    group3 = group3.substring(group3.indexOf(',') + 1);
                group3 = deformat(group3);
                final String g3f = group3;
                assEvents.add(new Runnable() {
                    boolean triggered1 = false;
                    boolean triggered2 = false;
                    @Override
                    public void run() {
                        if (!triggered1) {
                            if (assTime >= ts1) {
                                assLines.add(g3f);
                                triggered1 = true;
                            }
                        } else if (!triggered2) {
                            if (assTime >= ts2) {
                                if (!assLines.removeFirst().equals(g3f))
                                    System.err.println("Warning: ASS line tracking failure");
                                triggered2 = true;
                            }
                        }
                    }
                });
                // System.out.println(ts1 + ";" + ts2 + ";" + group3);
            }
        }
        fileInputStream.close();
    }

    public String advance() {
        for (Runnable r : assEvents)
            r.run();
        String n = "";
        for (String st : assLines) {
            if (n.length() != 0)
                n += " ";
            n += st;
        }
        return n;
    }

    private int dets(String s) {
        String[] dt = s.split(":");
        double a = Double.parseDouble(dt[0]);
        double b = Double.parseDouble(dt[1]);
        double c = Double.parseDouble(dt[2]);
        double timeSeconds = (a * 60 * 60) + (b * 60) + c;
        return (int) Math.floor(timeSeconds * 20);
    }

    private String deformat(String group3) {
        StringBuilder sb = new StringBuilder();
        int disables = 0;
        for (char c : group3.toCharArray()) {
            if (c == '{')
                disables++;
            if (disables == 0)
                sb.append(c);
            if (c == '}')
                disables--;
        }
        return sb.toString();
    }
}
