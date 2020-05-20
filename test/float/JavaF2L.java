import java.math.BigDecimal;
import java.math.BigInteger;

public class JavaF2L {
    static boolean u64 = true;
    public static void main(String[] args) {
	for (String a : args) {
	    double d = Double.parseDouble(a);
	    float f = (float)d;
	    
	    System.out.print(f + "f");
	    System.out.print(" ");
	    System.out.print(d + "d");
	    if (d >= 0x1p63 && u64) {
		{
		    System.out.print(" ");
		    long l = (long)(f/2);
		    BigInteger i = BigInteger.valueOf(l).multiply(BigInteger.valueOf(2));
		    System.out.print(i + "uL");
		}
		{
		    System.out.print(" ");
		    long l = (long)(d/2);
		    BigInteger i = BigInteger.valueOf(l).multiply(BigInteger.valueOf(2));
		    System.out.print(i + "uL");
		}
	    } else {
		System.out.print(" ");
		System.out.print(((long)f) + "L");
		System.out.print(" ");
		System.out.print(((long)d) + "L");
	    }
	    System.out.println();
	}
    }
}
