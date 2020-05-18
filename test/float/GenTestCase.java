import java.math.BigInteger;
class GenTestCase {
    static long min = 0 - (1 << 31);
    static long max = (1 << 31) - 1;
    public static void main(String[] args) {
	IntType t = new IntType(false, 64);
	doFractions(t);
	t.doCaseF("-0f", 0-0f);
	doCasesAround(t, 0);
	//	doCasesAround(t, BigInteger.valueOf(Long.MIN_VALUE));
	doCasesAround(t, BigInteger.ZERO.setBit(64).subtract(BigInteger.valueOf(1)));
	doCasesAround(t, BigInteger.ZERO.setBit(63));
	//doCasesAround(t, t.min);
	//doCasesAround(t, t.max);
	doInfinities(t);
    }

    static void doInfinities(IntType t) {
	t.doCaseF("-1e+300f", Float.NEGATIVE_INFINITY);
	t.doCaseF("1e+300f", Float.POSITIVE_INFINITY);
	t.doCaseF("float.nan", 0f/0f);
    }

    static void doFractions(IntType t) {
	for (float val = -3.0f; val < 3.25f; val += 0.25) {
	    t.doCaseF(val + "f", val);
	}
    }
    
    static void doCasesAround(IntType t, long num) {
	for (int inc : new int[]{-313, 313}) {
	    long val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCaseF(val + "f", (float)val);
		t.doCaseF((val + inc) + "f", (float)(val + inc));
		val = nextFloat(val, inc);
	    }
	}
    }

    static void doCasesAround(IntType t, BigInteger num) {
	for (BigInteger inc : new BigInteger[]{BigInteger.valueOf(0 - (1 << 23)), BigInteger.valueOf(1 << 23) }) {
	    BigInteger val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCaseF(val + "f", val.floatValue());
		val = nextFloat(val, inc);
	    }
	}
    }
    
    static long nextFloat(long val, int inc) {
	float v = (float)val;
	while (v == (long)val) {
	    val += inc;
	}
	return val;
    }
    static BigInteger nextFloat(BigInteger val, BigInteger inc) {
	float v = val.floatValue();
	while (v == val.floatValue()) {
	    val = val.add(inc);
	}
	return val;
    }
    static double nextDouble(long val, int inc) {
	double v = (double)val;
	while (v == (long)val) {
	    val += inc;
	}
	return val;
    }
}
class IntType {
    String name;
    long min;
    long max;
    IntType(boolean signed, int width) {
	if (signed) {
	    name = "i" + width;
	    min = 0L - (1L << (width-1));
	    max = (1L << (width-1)) - 1;
	} else {
	    name = "u" + width;
	    min = 0L;
	    max = (1L << (width)) - 1;
	}
	
    }
    void doCaseF(String rep, float val) {
	long result = (long)val;
	if (result < min) result = (long)min;
	if (result > max) result = (long)max;
	System.out.println("\t(" + rep + ", " + result + "),");
    }
    void doCaseD(String rep, double val) {
	long result = (long)val;
	if (result < min) result = (long)min;
	if (result > max) result = (long)max;
	System.out.println("\t(" + rep + ", " + result + "),");
    }
}
