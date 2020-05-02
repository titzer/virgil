public class JavaEval {
    public static void main(String[] args) {
	if (args.length != 3) {
	    System.out.println("Usage: JavaEval <num> <op> <num>");
	    System.exit(2);
	}
	float a = Float.parseFloat(args[0]);
	float b = Float.parseFloat(args[2]);
	String op = args[1];
	float result = 0;
	if (op.equals("+")) {
	    result = a + b;
	} else if (op.equals("-")) {
	    result = a - b;
	} else if (op.equals("*")) {
	    result = a * b;
	} else if (op.equals("/")) {
	    result = a / b;
	} else if (op.equals("%")) {
	    result = a % b;
	} else if (op.equals("pow")) {
	    result = (float)Math.pow(a, b);
	} else if (op.equals("exp")) {
	    result = (float)Math.exp(a);
	} else if (op.equals("abs")) {
	    result = Math.abs(a);
	} else if (op.equals("sqrt")) {
	    result = (float)Math.sqrt(a);
	} else {
	    System.out.println("Unknown op: " + op);
	    System.exit(1);
	}
	System.out.println("" + result + "f");
    }
}
