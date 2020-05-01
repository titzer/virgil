public class FloatPrint {
    public static void main(String[] args) {
	for (String s : args) {
	    float val = Float.parseFloat(s);
	    System.out.println("\tassert_fv(\"" + s + "\", "
			       + String.format("0x%08X", Float.floatToIntBits(val))
			       + ");");
	}
    }
}
