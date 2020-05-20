import java.math.BigDecimal;

public class JavaI2F {
    public static void main(String[] args) {
	for (String a : args) {
	    BigDecimal bd = new BigDecimal(a);
	    double d = bd.doubleValue();
	    float f = bd.floatValue();
	    System.out.print(s(bd));
	    System.out.print(" " + f + "f");
	    System.out.print(" " + d + "d");
	    BigDecimal i = BigDecimal.valueOf(f);
	    System.out.print(" " + s(i));
	    i = BigDecimal.valueOf(d);
	    System.out.print(" " + s(i));
	    System.out.println();
	}
    }
    static String s(BigDecimal bd) {
	return bd.toPlainString().replaceAll("\\.0", "");
    }
}
