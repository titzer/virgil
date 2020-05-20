import java.math.BigInteger;
import java.math.BigDecimal;
import java.io.*;

class GenTestCase {
    static PrintStream out = System.out;
    static boolean ftrunc = false;
    static String fsuffix = ftrunc ? "f" : "d";
    static String ftype = ftrunc ? "float" : "double";
    static String template_name;
    static String template;

    public static void main(String[] args) throws java.io.IOException {
	template_name = args[0];
	template = loadFile(template_name);
	// genUnop();
	// genBinop();
	// genLongs();
	genC();
    }
    static BigInteger i64_min = BigInteger.ZERO.subtract(BigInteger.ZERO.setBit(63));
    static BigInteger i64_max = BigInteger.ZERO.setBit(63).subtract(BigInteger.ONE);
    static BigInteger u64_min = BigInteger.ZERO;
    static BigInteger u64_max = BigInteger.ZERO.setBit(64).subtract(BigInteger.ONE);
    
    static void genLongs() {
	printCasesAround(i64_min);
	printCasesAround(i64_max);
	printCasesAround(u64_min);
	printCasesAround(u64_max);
    }

    static void printCasesAround(BigInteger num) {
	for (BigInteger inc : new BigInteger[]{BigInteger.valueOf(0 - 11133), BigInteger.valueOf(11133) }) {
	    BigInteger val = num;
	    for (int i = 0; i < 5; i++) {
		double d = val.doubleValue();
		if (ftrunc) d = (float)d;
		printCase(d);
		val = nextDouble(val, inc);
	    }
	}
    }
    
    static void printCase(double val) {
	BigDecimal d = BigDecimal.valueOf(val);
	//	boolean isI64 = inRange(val, i64_min, i64_max);
	//	boolean isU64 = inRange(val, u64_min, u64_max);
	String i64 = saturate(val, i64_min, i64_max);
	String u64 = saturate(val, u64_min, u64_max);
	out.println("\t(" + val + fsuffix + ", " + i64 + "L, " + u64 +"uL),");
    }

    static boolean inRange(double val, BigInteger a, BigInteger b) {
	BigDecimal d = BigDecimal.valueOf(val);
	BigDecimal min = new BigDecimal(a);
	BigDecimal max = new BigDecimal(b);
	return d.compareTo(min) >= 0 && d.compareTo(max) <= 0;
    }

    static String saturate(double val, BigInteger a, BigInteger b) {
	BigDecimal d = BigDecimal.valueOf(val);
	double r = val;
	if (d.compareTo(new BigDecimal(a)) < 0) return a.toString();
	else if (d.compareTo(new BigDecimal(b)) > 0) return b.toString();
	if (ftrunc) r = (float)r;
	return BigDecimal.valueOf(r).toPlainString();
    }
    
    static void genC() throws java.io.IOException {
	int[] widths = {
	    //	    15, 16, 31, 32, 41, 52, 53
	     63
	};
	
	for (int width : widths) {
	    for (boolean signed : new boolean[]{true, false}) {
		IntType t = new IntType(signed, width);

		ByteArrayOutputStream os = new ByteArrayOutputStream();
		out = new PrintStream(os);

		//		doFractions(t);
		//		doCasesAround(t, 0);
		doIntCasesAround(t, t.min);
		doIntCasesAround(t, t.max);
		doIntCasesAround(t, t.min / 2);
		doIntCasesAround(t, t.max / 2);
		//		doInfinities(t);

		String inputs = os.toString("UTF8");
		String result = template
		    .replaceAll("FTYPE", ftype)
		    .replaceAll("ITYPE", t.name)
		    .replaceAll("INPUTS", inputs);
		out = new PrintStream(new FileOutputStream(t.name + template_name.replaceAll(".t3", ".v3")));
		out.println(result);
		out.close();

	    }
	}

    }

    static abstract class Unop {
	boolean isDouble;
	String ftype;
	String itype;
	String op;
	Unop(boolean isDouble, String op) {
	    this.isDouble = isDouble;
	    this.ftype = isDouble ? "double" : "float";
	    this.itype = isDouble ? "u64" : "u32";
	    this.op = op;
	}
	abstract double exec(double d);
    }
    
    static abstract class Binop {
	boolean isDouble;
	String ftype;
	String itype;
	String rtype;
	String opname;
	String op;
	Binop(boolean isDouble, String rtype, String opname, String op) {
	    this.isDouble = isDouble;
	    this.ftype = isDouble ? "double" : "float";
	    this.itype = isDouble ? "u64" : "u32";
	    this.rtype = rtype;
	    this.opname = opname;
	    this.op = op;
	}
	abstract Object exec(double a, double b);
    }
    
    static void genUnop() throws java.io.IOException {
	for (boolean isDouble : new boolean[]{false, true}) {
	    doUnop(new Unop(isDouble, "floor") {
		    double exec(double d) {
			return Math.floor(d);
		    }
		});
	    doUnop(new Unop(isDouble, "ceil") {
		    double exec(double d) {
			return Math.ceil(d);
		    }
		});
	    doUnop(new Unop(isDouble, "sqrt") {
		    double exec(double d) {
			return Math.sqrt(d);
		    }
		});
	    doUnop(new Unop(isDouble, "abs") {
		    double exec(double d) {
			return Math.abs(d);
		    }
		});
	}
    }

    static double cases[] = {
	Double.NEGATIVE_INFINITY,
	Double.NaN,
	-134e16,
	-0xFFFFFFp-3,
	-0xFFFFFFp-2,
	-0xFFFFFFp-1,
	-0xFFFFFFp0,
	-0xFFFFFFp1,
	-0xFFFFFFp2,
	-0xFFFFFFp3,
	-3.9,
	-1.5,
	-1.25,
	-1,
	-1e-40,
	-0.125,
	-1e-319,
	-0,
	0,
	0.625,
	1e-320,
	1e-41,
	2.25,
	5.75,
	0xFFFFFFp-3,
	0xFFFFFFp-2,
	0xFFFFFFp-1,
	0xFFFFFFp0,
	0xFFFFFFp1,
	0xFFFFFFp2,
	0xFFFFFFp3,
	13455.16,
	124e17,
	Double.POSITIVE_INFINITY,
    };
	
    static void doUnop(Unop op) throws java.io.IOException {
	ByteArrayOutputStream os = new ByteArrayOutputStream();
	out = new PrintStream(os);
	
	for (double f : cases) {
	    double val = f;
	    if (!op.isDouble) val = (float)val;
	    double result = op.exec(val);
	    if (!op.isDouble) result = (float)result;
	    out.println("\t(" + render(op.isDouble, val) + ", " + render(op.isDouble, result) + ", " + Double.isNaN(result) + "),");
	}
	out.println("\t(0, 0, false)");
	    
	String inputs = os.toString("UTF8");
	String result = template
	    .replaceAll("FTYPE", op.ftype)
	    .replaceAll("ITYPE", op.itype)
	    .replaceAll("OP", op.op)
	    .replaceAll("INPUTS", inputs);
	    
	String outname = op.ftype +
	    template_name
	    .replaceAll("OP", op.op)
	    .replaceAll(".t3", ".v3");
	
	out = new PrintStream(new FileOutputStream(outname));
	out.println(result);
	out.close();
    }

    static void genBinop() throws java.io.IOException {
	for (boolean isDouble : new boolean[]{false, true}) {
	    doBinop(new Binop(isDouble, isDouble ? "double" : "float", "add", "+") {
		    Object exec(double a, double b) {
			return a + b;
		    }
		});
	    doBinop(new Binop(isDouble, isDouble ? "double" : "float", "sub", "-") {
		    Object exec(double a, double b) {
			return a - b;
		    }
		});
	    doBinop(new Binop(isDouble, isDouble ? "double" : "float", "mul", "*") {
		    Object exec(double a, double b) {
			return a * b;
		    }
		});
	    doBinop(new Binop(isDouble, isDouble ? "double" : "float", "div", "/") {
		    Object exec(double a, double b) {
			return a / b;
		    }
		});
	    doBinop(new Binop(isDouble, isDouble ? "double" : "float", "mod", "%") {
		    Object exec(double a, double b) {
			return a % b;
		    }
		});
	    
	    doBinop(new Binop(isDouble, "bool", "eq", "==") {
		    Object exec(double a, double b) {
			return a == b;
		    }
		});
	    doBinop(new Binop(isDouble, "bool", "ne", "!=") {
		    Object exec(double a, double b) {
			return a != b;
		    }
		});
	    doBinop(new Binop(isDouble, "bool", "lt", "<") {
		    Object exec(double a, double b) {
			return a < b;
		    }
		});
	    doBinop(new Binop(isDouble, "bool", "lteq", "<=") {
		    Object exec(double a, double b) {
			return a <= b;
		    }
		});
	    doBinop(new Binop(isDouble, "bool", "gt", ">") {
		    Object exec(double a, double b) {
			return a > b;
		    }
		});
	    doBinop(new Binop(isDouble, "bool", "gteq", ">=") {
		    Object exec(double a, double b) {
			return a >= b;
		    }
		});
	}
    }

    static void doBinop(Binop op) throws java.io.IOException {
	ByteArrayOutputStream os = new ByteArrayOutputStream();
	out = new PrintStream(os);
	
	for (int i = 0; i < cases.length; i++) {
	    for (int j = 0; j < cases.length; j++) {
		double a = cases[i];
		double b = cases[j];
		String comma = ",";
		if (i == cases.length - 1 && j == cases.length - 1) comma = "";
		if (!op.isDouble) a = (float)a;
		if (!op.isDouble) b = (float)b;
		Object result = op.exec(a, b);
		boolean isNaN = false;
		if (result instanceof Double) {
		    double r = ((Double)result).doubleValue();
		    if (!op.isDouble) r = (float)r;
		    result = render(op.isDouble, r);
		    isNaN = Double.isNaN(r);
		}
		out.println("\t("
			    + render(op.isDouble, a) + ", "
			    + render(op.isDouble, b) + ", "
			    + result + ", "
			    + isNaN + ")" + comma);
	    }
	}
	    
	String inputs = os.toString("UTF8");
	String result = template
	    .replaceAll("FTYPE", op.ftype)
	    .replaceAll("ITYPE", op.itype)
	    .replaceAll("RTYPE", op.rtype)
	    .replaceAll("OP", op.op)
	    .replaceAll("INPUTS", inputs);
	    
	String outname = op.ftype +
	    template_name
	    .replaceAll("OP", op.opname)
	    .replaceAll(".t3", ".v3");
	
	out = new PrintStream(new FileOutputStream(outname));
	out.println(result);
	out.close();
    }

    static String render(boolean isDouble, double d) {
	String suffix = isDouble ? "d" : "f";
	if (d >= Float.POSITIVE_INFINITY) return "1e+2000" + suffix;
	if (d <= Float.NEGATIVE_INFINITY) return "-1e+2000" + suffix;
	if (Double.isNaN(d)) return isDouble ? "double.nan" : "float.nan";
	return d + suffix;
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
	t.doCase(ftrunc, "-1e+2000" + fsuffix, Double.NEGATIVE_INFINITY);
	t.doCase(ftrunc, "1e+2000" + fsuffix, Double.POSITIVE_INFINITY);
	if (ftrunc) {
	    t.doCase(ftrunc, "float.nan", 0d/0d);
	} else {
	    t.doCase(ftrunc, "double.nan", 0d/0d);
	}
    }

    static void doFractions(IntType t) {
	for (double val = -3.0d; val < 3.25d; val += 0.25) {
	    t.doCase(ftrunc, val + fsuffix, val);
	}
    }

    static void doCasesAround(IntType t, long num) {
	for (int inc : new int[]{-311, 311}) {
	    long val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCase(ftrunc, val + fsuffix, (double)val);
		long val2 = ftrunc ? (long)(float)val : (long)(double)val;
		t.doCase(ftrunc, val2 + fsuffix, (double)val2);
		t.doCase(ftrunc, (val + inc) + fsuffix, (double)(val + inc));
		val = nextDouble(val, inc);
	    }
	}
    }

    static void doCasesAround(IntType t, BigInteger num) {
	for (BigInteger inc : new BigInteger[]{BigInteger.valueOf(0 - (1 << 23)), BigInteger.valueOf(1 << 23) }) {
	    BigInteger val = num;
	    for (int i = 0; i < 5; i++) {
		t.doCase(ftrunc, val + fsuffix, val.doubleValue());
		val = nextDouble(val, inc);
	    }
	}
    }

    static void doIntCasesAround(IntType t, long num) {
	for (int inc : new int[]{-311997, 311445}) {
	    long val = num;
	    for (int i = 0; i < 5; i++) {
		//		t.doCase(ftrunc, val + fsuffix, (double)val);
		long val2 = ftrunc ? (long)(float)val : (long)(double)val;
		t.doCase(ftrunc, val2 + fsuffix, (double)val2);
		//		t.doCase(ftrunc, (val + inc) + fsuffix, (double)(val + inc));
		val = nextDouble(val, inc);
	    }
	}
    }

    static BigInteger nextDouble(BigInteger val, BigInteger inc) {
	double s = val.doubleValue();
	if (ftrunc) s = (float)s;
	double v = s;
	while (v == s) {
	    val = val.add(inc);
	    v = val.doubleValue();
	    if (ftrunc) v = (float)v;
	}
	return val;
    }
    static long nextDouble(long val, int inc) {
	double v = (double)val;
	while (ftrunc ? (float)v == (long)(float)val : v == (long)val) {
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
    void doCase(boolean ftrunc, String rep, double val) {
	long result = ftrunc ? (long)(float)val : (long)val;
	boolean ok = val == (ftrunc ? (float)result : (double)result);
	if (result < min) ok = false;
	if (result > max) ok = false;
	GenTestCase.out.println("\t(" + rep + ", " + ok + "),");
    }
}
