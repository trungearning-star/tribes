import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import javax.microedition.lcdui.Font;
import javax.microedition.lcdui.Graphics;

public final class c {
   private f owner;
   private String[] shortText;
   private String[] helpText;
   private String[] sceneText;
   private String[] qText;
   private int[] qX;
   private int[] qY;
   private int[] qAlign;
   private int[] qStyle;
   private int qCount;
   private int sceneBase;
   private String[] lines;
   private int wx;
   private int wy;
   private int ww;
   private int wh;
   private int wstyle;
   private static final int MAX_Q = 96;
   private static final int MAX_LINES = 160;
   f a;
   byte[] a;
   short[] a;
   byte[] b;
   short[] b;
   byte[] c;
   short[] c;
   byte[][] a;
   short[][] a;
   String[] a;
   byte[][] b;
   byte[][] c;
   byte[] d;
   short[] d;
   short[] e;
   short[] f;
   byte[] e;
   byte a;
   byte b;
   byte c;
   byte[] f;
   int a;
   InputStream a;
   int b;
   int c;
   int d;
   int e;
   int f;
   int g;
   int h;
   byte d;
   int i;
   int j;
   int k;
   int l;
   int m;
   int n;
   int o;
   int p;
   int q;
   short[] g;
   short[] h;
   int r;
   int s;
   int t;
   int u;
   int v;
   int w;
   int x;
   int y;
   int z;
   int A;

   public c(f var1) {
      this.owner = var1;
      this.qText = new String[96];
      this.qX = new int[96];
      this.qY = new int[96];
      this.qAlign = new int[96];
      this.qStyle = new int[96];
      this.shortText = this.loadParts("/0/s");
      this.helpText = this.loadParts("/0/t");
      this.sceneText = this.loadParts("/0/d0");
      this.lines = new String[0];
      this.qCount = 0;
      this.sceneBase = 0;
   }

   final void a() {
      this.qCount = 0;
   }

   final void a(int var1) {
      this.sceneBase = sceneBaseFor(var1);
      if (this.sceneText == null || this.sceneText.length == 0) {
         this.sceneText = this.loadParts("/0/d0");
      }

   }

   final void b(int var1) {
      if (var1 == 0) {
         this.shortText = this.loadParts("/0/s");
      } else if (var1 == 1) {
         this.helpText = this.loadParts("/0/t");
      } else if (var1 == 2) {
         this.sceneText = this.loadParts("/0/d0");
         this.sceneBase = 0;
      }

   }

   final void a(int var1, int var2, int var3, String var4, int var5) {
      this.enqueue(var1, var2, var3, var4, var5);
   }

   final void a(int var1, int var2, int var3, int var4, int var5) {
      this.enqueue(var1, var2, var3, this.lookupShort(var4), var5);
   }

   final void a(int var1, int var2, int var3, int var4, int var5, int var6, int var7) {
      int var8 = var1;
      if (var4 >= 0) {
         String var9 = this.lookupShort(var4);
         this.enqueue(var1, var2, 0, var9, var7);
         var8 = var1 + this.textWidth(var9) + 2;
      }

      if (var5 >= 0) {
         String var10 = this.lookupShort(var5);
         this.enqueue(var8, var2, 0, var10, var7);
         var8 += this.textWidth(var10) + 2;
      }

      if (var6 >= 0) {
         String var11 = this.lookupShort(var6);
         this.enqueue(var8, var2, 0, var11, var7);
      }

   }

   final void a(Graphics var1) {
      this.prepareFont(var1);

      for(int var2 = 0; var2 < this.qCount; ++var2) {
         this.drawOutlined(var1, this.qText[var2], this.qX[var2], this.qY[var2], this.qAlign[var2], this.qStyle[var2]);
      }

      this.qCount = 0;
   }

   final void b() {
   }

   final void a(int var1, int var2, int var3) {
   }

   final void b(int var1, int var2, int var3, int var4, int var5, int var6, int var7) {
      this.wx = var1;
      this.wy = var2;
      this.ww = var3;
      this.wh = var4;
      this.wstyle = var7;
      String var8 = this.lookupLong(var5);
      this.lines = this.wrapText(var8, var3 <= 0 ? 300 : var3);
   }

   final void a(Graphics var1, int var2) {
      this.prepareFont(var1);
      Font var3 = var1.getFont();
      int var4 = var3.getHeight();
      int var5 = var4 + 1;
      byte var6 = 1;
      byte var7 = 1;
      int var8 = this.wh > var6 + var7 ? this.wh - var6 - var7 : this.wh;
      int var9 = this.wh <= 0 ? this.lines.length : var8 / var5;
      if (var9 < 1) {
         var9 = 1;
      }

      int var10 = var1.getClipX();
      int var11 = var1.getClipY();
      int var12 = var1.getClipWidth();
      int var13 = var1.getClipHeight();

      try {
         if (this.ww > 0 && this.wh > 0) {
            var1.setClip(this.wx, this.wy, this.ww, this.wh);
         }

         int var14 = this.wy + var6;

         for(int var15 = var2; var15 < this.lines.length && var15 < var2 + var9; ++var15) {
            this.drawOutlined(var1, this.lines[var15], this.wx, var14, 0, this.wstyle);
            var14 += var5;
         }
      } finally {
         var1.setClip(var10, var11, var12, var13);
      }

   }

   private void enqueue(int var1, int var2, int var3, String var4, int var5) {
      if (var4 == null) {
         var4 = "";
      }

      var4 = this.cleanInline(var4);
      if (this.qCount < 96) {
         this.qText[this.qCount] = var4;
         this.qX[this.qCount] = var1;
         this.qY[this.qCount] = var2;
         this.qAlign[this.qCount] = var3;
         this.qStyle[this.qCount] = var5;
         ++this.qCount;
      }
   }

   private String lookupShort(int var1) {
      if (var1 >= 0 && var1 < this.shortText.length) {
         return this.shortText[var1];
      } else {
         return var1 >= 0 && var1 < this.helpText.length ? this.helpText[var1] : "";
      }
   }

   private String lookupLong(int var1) {
      if (var1 >= 71) {
         int var2 = var1 - 71 + this.sceneBase;
         if (var2 >= 0 && this.sceneText != null && var2 < this.sceneText.length) {
            return this.sceneText[var2];
         }
      }

      if (var1 >= 0 && var1 < this.helpText.length) {
         return this.helpText[var1];
      } else {
         return var1 >= 0 && this.sceneText != null && var1 < this.sceneText.length ? this.sceneText[var1] : "";
      }
   }

   private static int sceneBaseFor(int var0) {
      int[] var1 = new int[]{0, 3, 15, 18, 20, 22, 24, 26, 28, 29, 30, 31, 33, 34, 35, 36, 44, 45, 46, 57, 58, 59, 62, 64, 65, 67, 68, 70, 72, 77, 81, 84, 85, 86, 97, 102, 108, 109, 111, 116, 117, 119, 123, 128, 137, 143, 145, 148, 149, 165, 167, 181, 184, 190, 197, 203, 204, 207, 208, 211, 212, 216, 219, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234};
      if (var0 < 0) {
         return 0;
      } else {
         return var0 >= var1.length ? var1[var1.length - 1] : var1[var0];
      }
   }

   private String[] loadParts(String var1) {
      try {
         InputStream var2 = this.getClass().getResourceAsStream(var1);
         if (var2 == null) {
            return new String[0];
         } else {
            ByteArrayOutputStream var3 = new ByteArrayOutputStream();
            byte[] var4 = new byte[512];

            int var5;
            while((var5 = var2.read(var4)) > 0) {
               var3.write(var4, 0, var5);
            }

            var2.close();
            return split(decodeUtf8(var3.toByteArray()), '|');
         }
      } catch (Exception var6) {
         return new String[0];
      }
   }

   private static String decodeUtf8(byte[] var0) {
      char[] var1 = new char[var0.length];
      int var2 = 0;
      int var3 = 0;

      while(var3 < var0.length) {
         int var4 = var0[var3++] & 255;
         if (var4 < 128) {
            var1[var2++] = (char)var4;
         } else if ((var4 & 224) == 192 && var3 < var0.length) {
            int var8 = var0[var3++] & 63;
            var1[var2++] = (char)((var4 & 31) << 6 | var8);
         } else if ((var4 & 240) == 224 && var3 + 1 < var0.length) {
            int var5 = var0[var3++] & 63;
            int var6 = var0[var3++] & 63;
            var1[var2++] = (char)((var4 & 15) << 12 | var5 << 6 | var6);
         } else {
            var1[var2++] = '?';
         }
      }

      return new String(var1, 0, var2);
   }

   private static String[] split(String var0, char var1) {
      int var2 = 1;

      for(int var3 = 0; var3 < var0.length(); ++var3) {
         if (var0.charAt(var3) == var1) {
            ++var2;
         }
      }

      String[] var7 = new String[var2];
      int var4 = 0;
      int var5 = 0;

      for(int var6 = 0; var6 < var0.length(); ++var6) {
         if (var0.charAt(var6) == var1) {
            var7[var5++] = var0.substring(var4, var6);
            var4 = var6 + 1;
         }
      }

      var7[var5] = var0.substring(var4);
      return var7;
   }

   private void prepareFont(Graphics var1) {
      try {
         var1.setFont(Font.getFont(0, 0, 8));
      } catch (Exception var3) {
      }

   }

   private int textWidth(String var1) {
      try {
         return Font.getFont(0, 0, 8).stringWidth(var1);
      } catch (Exception var3) {
         return var1.length() * 6;
      }
   }

   private void drawOutlined(Graphics var1, String var2, int var3, int var4, int var5, int var6) {
      if (var2 != null && var2.length() != 0) {
         Font var7 = var1.getFont();
         int var8 = var7.stringWidth(var2);
         int var9 = var3 - var8 * var5 / 2;
         var1.setColor(0);
         var1.drawString(var2, var9 - 1, var4, 20);
         var1.drawString(var2, var9 + 1, var4, 20);
         var1.drawString(var2, var9, var4 - 1, 20);
         var1.drawString(var2, var9, var4 + 1, 20);
         if (var6 == 1) {
            var1.setColor(16776960);
         } else if (var6 == 2) {
            var1.setColor(16744448);
         } else {
            var1.setColor(16777215);
         }

         var1.drawString(var2, var9, var4, 20);
      }
   }

   private String cleanInline(String var1) {
      StringBuffer var2 = new StringBuffer();

      for(int var3 = 0; var3 < var1.length(); ++var3) {
         char var4 = var1.charAt(var3);
         if (var4 >= ' ' && var4 != '&') {
            var2.append(var4);
         } else if (var4 == '&') {
            var2.append(' ');
         }
      }

      return var2.toString();
   }

   private String[] wrapText(String var1, int var2) {
      var1 = normalizeLong(var1);
      String[] var3 = new String[160];
      int var4 = 0;

      int var6;
      for(int var5 = 0; var5 <= var1.length() && var4 < 160; var5 = var6 + 1) {
         var6 = indexOf(var1, '\n', var5);
         if (var6 < 0) {
            var6 = var1.length();
         }

         var4 = this.wrapPara(var1.substring(var5, var6), var2, var3, var4);
         if (var6 == var1.length()) {
            break;
         }

         if (var4 < 160) {
            var3[var4++] = "";
         }
      }

      String[] var9 = new String[var4];

      for(int var7 = 0; var7 < var4; ++var7) {
         var9[var7] = var3[var7];
      }

      return var9;
   }

   private int wrapPara(String var1, int var2, String[] var3, int var4) {
      var1 = trim(var1);
      if (var1.length() == 0) {
         if (var4 < 160) {
            var3[var4++] = "";
         }

         return var4;
      } else {
         Font var5 = Font.getFont(0, 0, 8);
         StringBuffer var6 = new StringBuffer();
         int var7 = 0;

         while(var7 < var1.length() && var4 < 160) {
            while(var7 < var1.length() && var1.charAt(var7) == ' ') {
               ++var7;
            }

            int var8;
            for(var8 = var7; var8 < var1.length() && var1.charAt(var8) != ' '; ++var8) {
            }

            String var9 = var1.substring(var7, var8);
            String var10;
            if (var6.length() == 0) {
               var10 = var9;
            } else {
               StringBuffer var11 = new StringBuffer();
               var11.append(var6.toString());
               var11.append(' ');
               var11.append(var9);
               var10 = var11.toString();
            }

            if (var6.length() > 0 && var5.stringWidth(var10) > var2) {
               var3[var4++] = var6.toString();
               var6.setLength(0);
            } else {
               if (var6.length() > 0) {
                  var6.append(' ');
               }

               var6.append(var9);
               var7 = var8;
            }

            if (var6.length() == 0 && var9.length() > 0) {
               var6.append(var9);
               var7 = var8;
            }
         }

         if (var6.length() > 0 && var4 < 160) {
            var3[var4++] = var6.toString();
         }

         return var4;
      }
   }

   private static String normalizeLong(String var0) {
      StringBuffer var1 = new StringBuffer();

      for(int var2 = 0; var2 < var0.length(); ++var2) {
         char var3 = var0.charAt(var2);
         if (var3 == '&') {
            var1.append('\n');
         } else if (var3 >= ' ') {
            var1.append(var3);
         } else {
            var1.append(' ');
         }
      }

      return var1.toString();
   }

   private static int indexOf(String var0, char var1, int var2) {
      for(int var3 = var2; var3 < var0.length(); ++var3) {
         if (var0.charAt(var3) == var1) {
            return var3;
         }
      }

      return -1;
   }

   private static String trim(String var0) {
      int var1 = 0;

      int var2;
      for(var2 = var0.length(); var1 < var2 && var0.charAt(var1) <= ' '; ++var1) {
      }

      while(var2 > var1 && var0.charAt(var2 - 1) <= ' ') {
         --var2;
      }

      return var0.substring(var1, var2);
   }
}
