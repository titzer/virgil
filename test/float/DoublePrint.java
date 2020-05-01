public class DoublePrint {
    public static void main(String[] args) {
	for (String s : args) {
	    double val = Double.parseDouble(s);
	    System.out.println("\tassert_dv(\"" + s + "\", "
			       + String.format("0x%016X", Double.doubleToLongBits(val))
			       + ");");
	}
    }
}
