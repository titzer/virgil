import java.math.BigInteger;
import java.io.*;

class GenTestCase {
    static PrintStream out = System.out;

    public static void main(String[] args) throws java.io.IOException {
	String template_name = args[0];
	String template = loadFile(template_name);

	int[] widths = {
	    15, 16, 31, 32, 41, 52, 53, 63
	};


	for (int width : widths) {
	    for (boolean signed : new boolean[]{true, false}) {
		IntType t = new IntType(signed, width);

		ByteArrayOutputStream os = new ByteArrayOutputStream();
		out = new PrintStream(os);

		doFractions(t);
		t.doCaseF("-0d", 0-0d);
		doCasesAround(t, 0);
		//	doCasesAround(t, BigInteger.valueOf(Long.MIN_VALUE));
		//doCasesAround(t, BigInteger.ZERO.setBit(64).subtract(BigInteger.valueOf(1)));
		//doCasesAround(t, BigInteger.ZERO.setBit(63));
		doCasesAround(t, t.min);
		doCasesAround(t, t.max);
		doInfinities(t);
		out.print("\t(0, 0)");

		String inputs = os.toString("UTF8");
		String result = template.replaceAll("TYPE", t.name).replaceAll("INPUTS", inputs);
		out = new PrintStream(new FileOutputStream(t.name + template_name));
		out.println(result);
		out.close();

	    }
	}

    }

    private static String loadFile(String filePath) throws java.io.IOException {
	StringBuilder contentBuilder = new StringBuilder();
	try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {

	    String sCurrentLine;
	    while ((sCurrentLine = br.readLine()) != null) {
		contentBuilder.append(sCurrentLine).append("\n");
	    }
	} catch (IOException e) {
	    throw e;
	}
	return contentBuilder.toString();
    }

    static void doInfinities(IntType t) {
	t.doCaseF("-1e+300d", Double.NEGATIVE_INFINITY);
	t.doCaseF("1e+300d", Double.POSITIVE_INFINITY);
	t.doCaseF("double.nan", 0d/0d);
    }

    static void doFractions(IntType t) {
	for (double val = -3.0d; val < 3.25d; val += 0.25) {
	    t.doCaseF(val + "d", val);
	}
    }

    static void doCasesAround(IntType t, long num) {
	for (int inc : new int[]{-313, 313}) {
	    long val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCaseF(val + "d", (double)val);
		t.doCaseF((val + inc) + "d", (double)(val + inc));
		val = nextDouble(val, inc);
	    }
	}
    }

    static void doCasesAround(IntType t, BigInteger num) {
	for (BigInteger inc : new BigInteger[]{BigInteger.valueOf(0 - (1 << 23)), BigInteger.valueOf(1 << 23) }) {
	    BigInteger val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCaseF(val + "f", val.doubleValue());
		val = nextDouble(val, inc);
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
    static BigInteger nextDouble(BigInteger val, BigInteger inc) {
	double v = val.doubleValue();
	while (v == val.doubleValue()) {
	    val = val.add(inc);
	}
	return val;
    }
    static long nextDouble(long val, int inc) {
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
    String suffix ;
    IntType(boolean signed, int width) {
	if (signed) {
	    name = "i" + width;
	    min = 0L - (1L << (width-1));
	    max = (1L << (width-1)) - 1;
	    suffix = "";
	} else {
	    name = "u" + width;
	    min = 0L;
	    max = (1L << (width)) - 1;
	    suffix = width == 32 ? "u" : "";
	}

    }
    void doCaseF(String rep, double val) {
	long result = (long)val;
	if (result < min) result = (long)min;
	if (result > max) result = (long)max;
	GenTestCase.out.println("\t(" + rep + ", " + result + suffix + "),");
    }
    void doCaseD(String rep, double val) {
	long result = (long)val;
	if (result < min) result = (long)min;
	if (result > max) result = (long)max;
	GenTestCase.out.println("\t(" + rep + ", " + result + suffix + "),");
    }
}
