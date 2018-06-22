/*
 * stopEngine - OCRCNT Encoder
 * Written starting in 2018 by 20kdc
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package stopengine;

public class OCPal {
    public static int[] ocPal = new int[256];
    static {
        int[] rTab = {
                0x00,
                0x33,
                0x66,
                0x99,
                0xCC,
                0xFF
        };
        int[] gTab = {
                0x00,
                0x24,
                0x49,
                0x6D,
                0x92,
                0xB6,
                0xDB,
                0xFF
        };
        int[] bTab = {
                0x00,
                0x40,
                0x80,
                0xC0,
                0xFF
        };
        int[] grTab = {
                0x0F,
                0x1E,
                0x2D,
                0x3C,
                0x4B,
                0x5A,
                0x69,
                0x78,
                0x87,
                0x96,
                0xA5,
                0xB4,
                0xC3,
                0xD2,
                0xE1,
                0xF0
        };
        int base = 0;
        for (int i = 0; i < 16; i++)
            ocPal[base++] = (grTab[i] << 16) | (grTab[i] << 8) | grTab[i];
        for (int r = 0; r < rTab.length; r++)
            for (int g = 0; g < gTab.length; g++)
                for (int b = 0; b < bTab.length; b++)
                    ocPal[base++] = (rTab[r] << 16) | (gTab[g] << 8) | bTab[b];
    }

    public static int find(int i) {
        int md = 0x7FFFFFFF;
        int mdI = 0;
        for (int j = 0; j < ocPal.length; j++) {
            int cd = getDist(ocPal[j], i);
            if (cd < md) {
                md = cd;
                mdI = j;
            }
        }
        return mdI;
    }

    private static int getDist(int ipx, int ipx1) {
        int rD = Math.abs(((ipx & 0xFF0000) >> 16) - ((ipx1 & 0xFF0000) >> 16));
        int gD = Math.abs(((ipx & 0xFF00) >> 8) - ((ipx1 & 0xFF00) >> 8));
        int bD = Math.abs((ipx & 0xFF) - (ipx1 & 0xFF));
        return (rD + gD + bD) + (((rD + gD + bD) / 3) * 4);
    }
}
