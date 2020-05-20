import java.math.BigDecimal;

public class JavaF2L {
    public static void main(String[] args) {
	for (String a : args) {
	    double d = Double.parseDouble(a);
	    float f = (float)d;
	    
	    System.out.print(f + "f");
	    System.out.print(" ");
	    System.out.print(d + "d");
	    System.out.print(" ");
	    if (d >= 0) {
		System.out.print(BigDecimal.valueOf(f).toPlainString());
		System.out.print(" ");
		System.out.print(BigDecimal.valueOf(d).toPlainString());
		System.out.println();
	    } else {
		System.out.print(((long)f) + "L");
		System.out.print(" ");
		System.out.print(((long)d) + "L");
		System.out.println();
	    }
	    
	}
    }
}
