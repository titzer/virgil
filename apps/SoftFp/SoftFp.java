class FloatValues {
    int counter;
    int next() {
	int i = counter++;
	int low = i & 0x7;
	int fill = ((i >> 1) & 0x1) * (0x1FFFF << 3);
	int mid = ((i >> 4) & 0x7) << 20;
	int exp = ((i >> 7) & 0x3) << 23;
	int bits = exp | mid | fill | low;
	return bits;
    }
    boolean hasNext() {
	return counter <= 0x1ff;
    }
}
public class SoftFp {
    public static int F32_SIGNIFICAND_SIZE = 23;
    public static int F32_EXP_MASK = 0xFF;
    public static int F32_EXP_BIAS = 127;
    public static int F32_MIN_EXP = -127;
    public static void main(String[] args) {
	//	doAdd(7798566, 1000 + 3003115);
	doAdd(7798566, 1000 + 3 * 3003115);

	for (FloatValues a = new FloatValues(); a.hasNext(); ) {
	    int i = a.next();
	    for (FloatValues b = new FloatValues(); b.hasNext(); ) {
		int j = b.next();
		doAdd(i, j);
	    }
	}
    }
    private static void doAdd(int i, int j) {
	float a = Float.intBitsToFloat(i);
	float b = Float.intBitsToFloat(j);
	float result = a + b;
	System.out.println(toBits(a) + " + " + toBits(b) + " = " + toBits(result));
    }
    private static String toBits(float f) {
	int a = Float.floatToRawIntBits(f);
	StringBuilder b = new StringBuilder();
	b.append(a < 0 ? "1" : "0");
	b.append(" ");
	
	int biased_exp = (a >>> F32_SIGNIFICAND_SIZE) & F32_EXP_MASK;
	int exp = biased_exp == 0 ?  F32_MIN_EXP : biased_exp - F32_EXP_BIAS;

	b.append(exp);

	b.append(" ");

	for (int i = 1 << F32_SIGNIFICAND_SIZE - 1; i != 0; i >>= 1) {
	    int bit = (((a & i) != 0) ? 1 : 0);
	    b.append(bit);
	}

	return b.toString();
    }
}
