// Copyright 2008 Google Inc. All rights reserved.
// See LICENSE for details of Apache 2.0 license.

import java.io.*;

/**
 * The <code>V3S_System</code> class implements system calls for Virgil III programs compiled
 * to Java bytecode.
 */
public class V3S_System {
    private static final int PRINT_SIZE = 128;
    private static final int MAX_FILES = 128;

    private static final int INT_MAX = 0x7fffffff;
    private static final long LONG_MAX = 0x7fffffffffffffffL;
    private static final long U64_MAX = 0xffffffffffffffffL;

    public static final InputStream[] fileInput;
    public static final OutputStream[] fileOutput;

    static {
        fileInput = new InputStream[MAX_FILES];
        fileOutput = new OutputStream[MAX_FILES];
	fileInput[0] = System.in;
	fileOutput[1] = System.out;
	fileOutput[2] = System.err;
    }

    public static void putc(char ch) {
        System.out.print((char) ch);
    }

    public static void puts(byte[] str) {
        System.out.write(str, 0, str.length);
    }

    public static void puti(int i) {
        System.out.print(i);
    }

    public static void ln() {
        System.out.print('\n');
    }

    public static int fileRead(int fd) throws IOException {
	InputStream in = getFileInput(fd);
        return in == null ? -1 : in.read();
    }

    public static void fileWriteK(int fd, byte[] b, int offset, int length) throws IOException {
	OutputStream out = getFileOutput(fd);
        if (out != null) out.write(b, offset, length);
    }

    public static int fileReadK(int fd, byte[] b, int offset, int length) throws IOException {
	InputStream in = getFileInput(fd);
        if (in != null) return in.read(b, offset, length);
        return 0;
    }

    public static int write(int fd, byte[] b, int offset, int length) throws IOException {
	OutputStream out = getFileOutput(fd);
        if (out != null) {
	    out.write(b, offset, length);
	    return length;
	}
        return 0;
    }

    public static int read(int fd, byte[] b, int offset, int length) throws IOException {
	InputStream in = getFileInput(fd);
        if (in != null) return in.read(b, offset, length);
        return 0;
    }

    public static int fileOpen(byte[] name, boolean input) {
        for (int i = 0; i < fileInput.length; i++) {
            if (fileInput[i] == null && fileOutput[i] == null) {
                File file = new File(new String(name));
                try {
                    if (input) fileInput[i] = new FileInputStream(file);
                    else fileOutput[i] = new FileOutputStream(file);
                    return i;
                } catch (Throwable t) {
                    return -1;
                }
            }
        }
        return -1;
    }

    public static int fileLeft(int fd) throws IOException {
	InputStream in = getFileInput(fd);
        if (in != null) return in.available();
	return 0;
    }

    public static void fileClose(int fd) {
        if (fd < 0) return;
        if (fd >= fileInput.length) return;
        try {
            if (fileInput[fd] != null) fileInput[fd].close();
            if (fileOutput[fd] != null) fileOutput[fd].close();
            fileInput[fd] = null;
            fileOutput[fd] = null;
        } catch (IOException e) {
            // do nothing.
        }
    }

    public static byte[] fileLoad(byte[] fname) {
        try {
            File file = new File(new String(fname));
            FileInputStream fis = new FileInputStream(file);
            byte[] buffer = new byte[(int)file.length()];
            int pos = 0;
            while (pos < buffer.length) {
                pos += fis.read(buffer, pos, buffer.length - pos);
            }
            fis.close();
            return buffer;
        } catch (IOException e) {
            return null;
        }
    }

    public static int ticksMs() {
        return (int) System.currentTimeMillis();
    }

    public static int ticksUs() {
        return (int) (System.nanoTime() / 1000);
    }

    public static int ticksNs() {
        return (int) System.nanoTime();
    }

    public static void chmod(byte[] fname, int mode) {
        String fileName = new String(fname);
        String modeString = Integer.toString(mode, 8);
	try {
            Runtime.getRuntime().exec(new String[] {"chmod", modeString, fileName}).waitFor();
        } catch (Throwable t) {
	    // do nothing.
	}
    }

    public static int exec(byte[][] args) throws Exception {
        String[] a = new String[args.length];
        for (int i = 0; i < args.length; i++) {
	    a[i] = new String(args[i]);
	}
	//        try {
	    return Runtime.getRuntime().exec(a).waitFor();
	    //        } catch (Throwable t) {
	    //            return -1;
	    //	}
    }

    private static InputStream getFileInput(int fd) {
	return (fd < 0 || fd > fileInput.length) ? null : fileInput[fd];
    }

    private static OutputStream getFileOutput(int fd) {
	return (fd < 0 || fd > fileOutput.length) ? null : fileOutput[fd];
    }

    public static void error(byte[] type, byte[] message) throws Exception {
        throw new Exception(new String(type) + ": " + new String(message));
    }

    public static boolean equals(Object a, Object b) {
        return a == b || (a == null ? b.equals(a) : a.equals(b));
    }

    public static int shl(int a, int b) {
	if ((b & 31) == b) return a << b;
	return 0;
    }

    public static int shr(int a, int b) {
	if ((b & 31) == b) return a >>> b;
	return 0;
    }

    public static int sar(int a, int b) {
	if (b >= 31) return a >> 31;
	return a >> b;
    }

    public static long lshl(long a, long b) {
	if ((b & 63) == b) return a << b;
	return 0;
    }

    public static long lshr(long a, long b) {
	if ((b & 63) == b) return a >>> b;
	return 0;
    }

    public static long lshr(long a, byte b, byte rem) {
        if (b == 0) return a;
        if (b >= 63) return 0;
        return (a << rem) >>> rem >>> b;
    }

    public static long lsar(long a, long b) {
	if (b >= 63) return a >> 63;
	return a >> b;
    }

    public static int natLt(int x, int y) {
        if (x < 0) return y < 0 ? (y > x ? 1 : 0) : 0;
        return (y < 0 || x < y) ? 1 : 0;
    }

    public static int natLteq(int x, int y) {
        if (x < 0) return y < 0 ? (y >= x ? 1 : 0) : 0;
        return (y < 0 || x <= y) ? 1 : 0;
    }

    public static int natDiv(int x, int y) {
	return (int)((x & 0xffffffffL) / (y & 0xffffffffL));
    }

    public static int natMod(int x, int y) {
	return (int)((x & 0xffffffffL) % (y & 0xffffffffL));
    }

    public static int natGt(int x, int y) {
        return 1 ^ natLteq(x, y);
    }

    public static int natGteq(int x, int y) {
        return 1 ^ natLt(x, y);
    }

    public static int natlLt(long x, long y) {
        if (x < 0) return y < 0 ? (y > x ? 1 : 0) : 0;
        return (y < 0 || x < y) ? 1 : 0;
    }

    public static int natlLteq(long x, long y) {
        if (x < 0) return y < 0 ? (y >= x ? 1 : 0) : 0;
        return (y < 0 || x <= y) ? 1 : 0;
    }

    public static int natlGt(long x, long y) {
        return 1 ^ natlLteq(x, y);
    }

    public static int natlGteq(long x, long y) {
        return 1 ^ natlLt(x, y);
    }

    public static long natlDiv(long x, long y) {
	if (y == 1) return x;
	if (y < 0) return natlGteq(x, y);
	long xs = x >>> 1, q = (xs / y) << 1;
	while (natlGteq(x - q*y, y) != 0) q++;
	return q;
    }

    public static long natlMod(long x, long y) {
	return x - (y * natlDiv(x, y));
    }

    public static int satInt(int v, int min, int max) {
	if (v < min) return min;
	if (v > max) return max;
	return v;
    }

    public static long satLong(long v, long min, long max) {
	if (v < min) return min;
	if (v > max) return max;
	return v;
    }

    public static long d2ul(double f) {
	if (f <= 0) return 0;
	if (f >= 18446744073709551616d) return 0xFFFFFFFFFFFFFFFFL;
	if (f > 9223372036854775000d) {
	    return ((long)(f / 2)) * 2;
	}
	return (long)f;
    }

    public static float cast_i2f(int v) {
	if (v != INT_MAX) {
            float f = (float)v;
            if (v == (int)f) return f;
        }
        throw new ClassCastException();
    }

    public static float cast_l2f(long v) {
	if (v != LONG_MAX) {
            float f = (float)v;
            if (v == (long)f) return f;
        }
        throw new ClassCastException();
    }

    public static double cast_l2d(long v) {
	if (v != LONG_MAX) {
            double d = (double)v;
            if (v == (long)d) return d;
        }
        throw new ClassCastException();
    }

    public static float cast_ul2f(long v) {
	if (v != U64_MAX) {
            if (v >= 0) return cast_l2f(v);
            // Manually check if any bits would be rounded off.
            if ((v & 0x0FFFFFFFFFFL) == 0) return 2.0f * (float)(v >>> 1);
        }
        throw new ClassCastException();
    }

    public static double cast_ul2d(long v) {
	if (v != U64_MAX) {
            if (v >= 0) return cast_l2d(v);
            // Manually check if any bits would be rounded off.
            if ((v & 0x7FFL) == 0) return 2.0d * (double)(v >>> 1);
        }
        throw new ClassCastException();
    }

    public static boolean query_i2f(int v) {
	return v != INT_MAX && v == (int)(float)v;
    }

    public static boolean query_l2f(long v) {
	return v != LONG_MAX && v == (long)(float)v;
    }

    public static boolean query_l2d(long v) {
	return v != LONG_MAX && v == (long)(double)v;
    }

    public static boolean query_ul2f(long v) {
	if (v == U64_MAX || v == LONG_MAX) return false;
	if (v < 0) {
	    if ((v & 1) != 0) return false;
	    v >>>= 1;
	}
	return v == (long)(float)v;
    }

    public static boolean query_ul2d(long v) {
	if (v == U64_MAX || v == LONG_MAX) return false;
	if (v < 0) {
	    if ((v & 1) != 0) return false;
	    v >>>= 1;
	}
	return v == (long)(double)v;
    }

    public static boolean query_d2f(double v) {
	long before = Double.doubleToRawLongBits(v);
	float f = (float)v;
	long after = Double.doubleToRawLongBits((double)f);
	return (before == after);
    }

    public static float cast_d2f(double v) {
	long before = Double.doubleToRawLongBits(v);
	float f = (float)v;
	long after = Double.doubleToRawLongBits((double)f);
	if (before == after) return f;
	throw new ClassCastException();
    }

    public static double round_ul2d(long v) {
	double r = (double)v;
	if (v < 0) return 2.0d * (double)((v >>> 1) | (v & 1));
	return r;
    }

    public static float round_ul2f(long v) {
	float r = (float)v;
	if (v < 0) return 2.0f * (float)((v >>> 1) | (v & 1));
	return r;
    }

    public static long cast_d2l(double v, double min, double max) {
	error: {
	    if (Double.doubleToLongBits(v) == 0x8000000000000000L) break error;
	    if (v < min || v >= max) break error;
	    if (v >= 0x1p63d) {  // XXX: only matters in u64 case
		long r = (long)(v/2);
		if (v != 2*(double)r) break error;
		return r << 1;
	    }
	    long r = (long)v;
	    if (v != (double)r) break error;
	    return r;
	}
	throw new ClassCastException();
    }

    public static boolean query_d2l(double v, double min, double max) {
	if (Double.doubleToLongBits(v) == 0x8000000000000000L) return false;
	if (v < min || v >= max) return false;
	if (v >= 0x1p63d) {  // XXX: only matters in u64 case
	    long r = (long)(v/2);
	    return v == 2*(double)r;
	}
	return v == (double)(long)v;
    }

    public static float fabs(float f) {
	int x = Float.floatToRawIntBits(f);
	return Float.intBitsToFloat((x << 1) >>> 1);
    }

    public static double dabs(double f) {
	long x = Double.doubleToRawLongBits(f);
	return Double.longBitsToDouble((x << 1) >>> 1);
    }

    public static boolean feq(float a, float b) {
	return Float.floatToRawIntBits(a) == Float.floatToRawIntBits(b);
    }

    public static boolean deq(double a, double b) {
	return Double.doubleToRawLongBits(a) == Double.doubleToRawLongBits(b);
    }

    public static byte readBytes1(byte[] bytes, int offset, int staticOffset) {
        return bytes[offset + staticOffset];
    }

    public static short readBytes2(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 1] & 0xFF) << 8;
        return ((short)(byte0 | byte1));
    }

    public static int readBytes3(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 1] & 0xFF) << 8;
        int byte2 = ((int)bytes[fullOffset + 2] & 0xFF) << 16;
        return byte0 | byte1 | byte2;
    }

    public static int readBytes4(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 1] & 0xFF) << 8;
        int byte2 = ((int)bytes[fullOffset + 2] & 0xFF) << 16;
        int byte3 = ((int)bytes[fullOffset + 3] & 0xFF) << 24;
        return byte0 | byte1 | byte2 | byte3;
    }

    public static long readBytes5(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 1] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 2] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 3] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 4] & 0xFF) << 32;
        return byte0 | byte1 | byte2 | byte3 | byte4;
    }

    public static long readBytes6(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 1] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 2] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 3] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 4] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 5] & 0xFF) << 40;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5;
    }

    public static long readBytes7(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 1] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 2] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 3] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 4] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 5] & 0xFF) << 40;
        long byte6 = ((long)bytes[fullOffset + 6] & 0xFF) << 48;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5 | byte6;
    }

    public static long readBytes8(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 1] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 2] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 3] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 4] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 5] & 0xFF) << 40;
        long byte6 = ((long)bytes[fullOffset + 6] & 0xFF) << 48;
        long byte7 = ((long)bytes[fullOffset + 7] & 0xFF) << 56;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5 | byte6 | byte7;
    }

    public static float readBytesFloat(byte[] bytes, int offset, int staticOffset) {
        int bits = V3S_System.readBytes4(bytes, offset, staticOffset);
        return Float.intBitsToFloat(bits);
    }

    public static double readBytesDouble(byte[] bytes, int offset, int staticOffset) {
        long bits = V3S_System.readBytes8(bytes, offset, staticOffset);
        return Double.longBitsToDouble(bits);
    }

    public static short readBytes2_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset + 1] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 0] & 0xFF) << 8;
        return ((short)(byte0 | byte1));
    }

    public static int readBytes3_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset + 2] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 1] & 0xFF) << 8;
        int byte2 = ((int)bytes[fullOffset + 0] & 0xFF) << 16;
        return byte0 | byte1 | byte2;
    }

    public static int readBytes4_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        int byte0 = ((int)bytes[fullOffset + 3] & 0xFF);
        int byte1 = ((int)bytes[fullOffset + 2] & 0xFF) << 8;
        int byte2 = ((int)bytes[fullOffset + 1] & 0xFF) << 16;
        int byte3 = ((int)bytes[fullOffset + 0] & 0xFF) << 24;
        return byte0 | byte1 | byte2 | byte3;
    }

    public static long readBytes5_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset + 4] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 3] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 2] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 1] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 0] & 0xFF) << 32;
        return byte0 | byte1 | byte2 | byte3 | byte4;
    }

    public static long readBytes6_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset + 5] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 4] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 3] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 2] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 1] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 0] & 0xFF) << 40;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5;
    }

    public static long readBytes7_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset + 6] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 5] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 4] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 3] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 2] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 1] & 0xFF) << 40;
        long byte6 = ((long)bytes[fullOffset + 0] & 0xFF) << 48;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5 | byte6;
    }

    public static long readBytes8_be(byte[] bytes, int offset, int staticOffset) {
        int fullOffset = offset + staticOffset;
        long byte0 = ((long)bytes[fullOffset + 7] & 0xFF);
        long byte1 = ((long)bytes[fullOffset + 6] & 0xFF) << 8;
        long byte2 = ((long)bytes[fullOffset + 5] & 0xFF) << 16;
        long byte3 = ((long)bytes[fullOffset + 4] & 0xFF) << 24;
        long byte4 = ((long)bytes[fullOffset + 3] & 0xFF) << 32;
        long byte5 = ((long)bytes[fullOffset + 2] & 0xFF) << 40;
        long byte6 = ((long)bytes[fullOffset + 1] & 0xFF) << 48;
        long byte7 = ((long)bytes[fullOffset + 0] & 0xFF) << 56;
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5 | byte6 | byte7;
    }

    public static float readBytesFloat_be(byte[] bytes, int offset, int staticOffset) {
        int bits = V3S_System.readBytes4_be(bytes, offset, staticOffset);
        return Float.intBitsToFloat(bits);
    }

    public static double readBytesDouble_be(byte[] bytes, int offset, int staticOffset) {
        long bits = V3S_System.readBytes8(bytes, offset, staticOffset);
        return Double.longBitsToDouble(bits);
    }

    public static void setBytes1(byte[] bytes, int offset, byte value, int staticOffset) {
        bytes[offset + staticOffset] = value;
    }

    public static void setBytes2(byte[] bytes, int offset, short value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
    }

    public static void setBytes3(byte[] bytes, int offset, int value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
    }

    public static void setBytes4(byte[] bytes, int offset, int value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
    }

    public static void setBytes5(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
        bytes[fullOffset + 4] = (byte)(value >> 32);
    }

    public static void setBytes6(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
        bytes[fullOffset + 4] = (byte)(value >> 32);
        bytes[fullOffset + 5] = (byte)(value >> 40);
    }

    public static void setBytes7(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
        bytes[fullOffset + 4] = (byte)(value >> 32);
        bytes[fullOffset + 5] = (byte)(value >> 40);
        bytes[fullOffset + 6] = (byte)(value >> 48);
    }

    public static void setBytes8(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
        bytes[fullOffset + 4] = (byte)(value >> 32);
        bytes[fullOffset + 5] = (byte)(value >> 40);
        bytes[fullOffset + 6] = (byte)(value >> 48);
        bytes[fullOffset + 7] = (byte)(value >> 56);
    }

    public static void setBytesFloat(byte[] bytes, int offset, float value, int staticOffset) {
        int bits = Float.floatToRawIntBits(value);
        V3S_System.setBytes4(bytes, offset, bits, staticOffset);
    }

    public static void setBytesDouble(byte[] bytes, int offset, double value, int staticOffset) {
        long bits = Double.doubleToRawLongBits(value);
        V3S_System.setBytes8(bytes, offset, bits, staticOffset);
    }

    public static void setBytes2_be(byte[] bytes, int offset, short value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 1] = (byte)value;
        bytes[fullOffset + 0] = (byte)(value >> 8);
    }

    public static void setBytes3_be(byte[] bytes, int offset, int value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 2] = (byte)value;
        bytes[fullOffset + 1] = (byte)(value >> 8);
        bytes[fullOffset + 0] = (byte)(value >> 16);
    }

    public static void setBytes4_be(byte[] bytes, int offset, int value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 3] = (byte)value;
        bytes[fullOffset + 2] = (byte)(value >> 8);
        bytes[fullOffset + 1] = (byte)(value >> 16);
        bytes[fullOffset + 0] = (byte)(value >> 24);
    }

    public static void setBytes5_be(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 4] = (byte)value;
        bytes[fullOffset + 3] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 1] = (byte)(value >> 24);
        bytes[fullOffset + 0] = (byte)(value >> 32);
    }

    public static void setBytes6_be(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 5] = (byte)value;
        bytes[fullOffset + 4] = (byte)(value >> 8);
        bytes[fullOffset + 2] = (byte)(value >> 16);
        bytes[fullOffset + 2] = (byte)(value >> 24);
        bytes[fullOffset + 1] = (byte)(value >> 32);
        bytes[fullOffset + 0] = (byte)(value >> 40);
    }

    public static void setBytes7_be(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 6] = (byte)value;
        bytes[fullOffset + 5] = (byte)(value >> 8);
        bytes[fullOffset + 4] = (byte)(value >> 16);
        bytes[fullOffset + 3] = (byte)(value >> 24);
        bytes[fullOffset + 2] = (byte)(value >> 32);
        bytes[fullOffset + 1] = (byte)(value >> 40);
        bytes[fullOffset + 0] = (byte)(value >> 48);
    }

    public static void setBytes8_be(byte[] bytes, int offset, long value, int staticOffset) {
        int fullOffset = offset + staticOffset;
        bytes[fullOffset + 7] = (byte)value;
        bytes[fullOffset + 6] = (byte)(value >> 8);
        bytes[fullOffset + 5] = (byte)(value >> 16);
        bytes[fullOffset + 4] = (byte)(value >> 24);
        bytes[fullOffset + 3] = (byte)(value >> 32);
        bytes[fullOffset + 2] = (byte)(value >> 40);
        bytes[fullOffset + 1] = (byte)(value >> 48);
        bytes[fullOffset + 0] = (byte)(value >> 56);
    }

    public static void setBytesFloat_be(byte[] bytes, int offset, float value, int staticOffset) {
        int bits = Float.floatToRawIntBits(value);
        V3S_System.setBytes4_be(bytes, offset, bits, staticOffset);
    }

    public static void setBytesDouble_be(byte[] bytes, int offset, double value, int staticOffset) {
        long bits = Double.doubleToRawLongBits(value);
        V3S_System.setBytes8_be(bytes, offset, bits, staticOffset);
    }
}
