// Copyright 2024 Virgil authors. All rights reserved.
// See LICENSE for details of Apache 2.0 license.
//
// MathRef: generates assertDoubleEq lines for MathTest.v3 by computing
// reference values using Java's standard math library.
//
// Usage:
//   javac MathRef.java
//   java MathRef <func> <arg>...
//   java MathRef atan2 <y> <x>...   (pairs of args)
//
// Supported functions: sin cos tan asin acos atan atan2 sinh cosh tanh exp log sqrt expm1
//
// Special argument tokens:
//   PI PI/2 PI/3 PI/4 PI/6 2*PI 3*PI/2 3*PI/4
//   E sqrt2 sqrt3 sqrt2/2 sqrt3/2
//   Inf -Inf NaN

public class MathRef {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: java MathRef <func> <arg>...");
            System.err.println("       java MathRef atan2 <y> <x>...");
            System.err.println("Funcs: sin cos tan asin acos atan atan2 sinh cosh tanh exp log sqrt expm1");
            System.err.println("Special args: PI PI/2 PI/3 PI/4 PI/6 2*PI 3*PI/2 E sqrt2 sqrt3 sqrt2/2 sqrt3/2 Inf -Inf NaN");
            System.exit(1);
        }
        String func = args[0];
        boolean twoArg = func.equals("atan2");
        int step = twoArg ? 2 : 1;
        for (int i = 1; i + step <= args.length; i += step) {
            String a1 = args[i];
            String a2 = twoArg ? args[i + 1] : null;
            double v1 = parseVal(a1);
            double result = twoArg ? Math.atan2(v1, parseVal(a2)) : apply(func, v1);
            String call = "Math." + func + "(" + fmtArg(a1) + (twoArg ? ", " + fmtArg(a2) : "") + ")";
            System.out.println("\t\tassertDoubleEq(t, " + fmtResult(result) + ", " + call + ");");
        }
    }

    static double apply(String f, double x) {
        switch (f) {
            case "sin":   return Math.sin(x);
            case "cos":   return Math.cos(x);
            case "tan":   return Math.tan(x);
            case "asin":  return Math.asin(x);
            case "acos":  return Math.acos(x);
            case "atan":  return Math.atan(x);
            case "sinh":  return Math.sinh(x);
            case "cosh":  return Math.cosh(x);
            case "tanh":  return Math.tanh(x);
            case "exp":   return Math.exp(x);
            case "log":   return Math.log(x);
            case "sqrt":  return Math.sqrt(x);
            case "expm1": return Math.expm1(x);
        }
        System.err.println("Unknown function: " + f);
        System.exit(1);
        return 0;
    }

    static double parseVal(String s) {
        switch (s) {
            case "PI":      return Math.PI;
            case "E":       return Math.E;
            case "PI/2":    return Math.PI / 2;
            case "PI/3":    return Math.PI / 3;
            case "PI/4":    return Math.PI / 4;
            case "PI/6":    return Math.PI / 6;
            case "2*PI":    return 2 * Math.PI;
            case "3*PI/2":  return 3 * Math.PI / 2;
            case "3*PI/4":  return 3 * Math.PI / 4;
            case "sqrt2":   return Math.sqrt(2);
            case "sqrt3":   return Math.sqrt(3);
            case "sqrt2/2": return Math.sqrt(2) / 2;
            case "sqrt3/2": return Math.sqrt(3) / 2;
            case "1/sqrt3": return 1.0 / Math.sqrt(3);
            case "Inf":     return Double.POSITIVE_INFINITY;
            case "-Inf":    return Double.NEGATIVE_INFINITY;
            case "NaN":     return Double.NaN;
        }
        return Double.parseDouble(s);
    }

    static String fmtArg(String s) {
        switch (s) {
            case "PI":      return "Math.PI";
            case "E":       return "Math.E";
            case "PI/2":    return "Math.PI / 2";
            case "PI/3":    return "Math.PI / 3";
            case "PI/4":    return "Math.PI / 4";
            case "PI/6":    return "Math.PI / 6";
            case "2*PI":    return "2 * Math.PI";
            case "3*PI/2":  return "3 * Math.PI / 2";
            case "3*PI/4":  return "3 * Math.PI / 4";
            case "sqrt2":   return "SQRT_2";
            case "sqrt3":   return "SQRT_3";
            case "sqrt2/2": return "SQRT_HALF";
            case "sqrt3/2": return "SQRT_3 / 2";
            case "1/sqrt3": return "1 / SQRT_3";
            case "Inf":     return "double.infinity";
            case "-Inf":    return "0d - double.infinity";
            case "NaN":     return "double.nan";
        }
        return s;
    }

    static String fmtResult(double x) {
        if (Double.isNaN(x)) return "double.nan";
        if (x == Double.POSITIVE_INFINITY) return "double.infinity";
        if (x == Double.NEGATIVE_INFINITY) return "0d - double.infinity";
        // Exact integers are more readable without decimal point
        long l = (long) x;
        if (x == l) return Long.toString(l);
        // Use Java's shortest round-trip decimal; lowercase e, add 'd' suffix
        return Double.toString(x).replace('E', 'e') + "d";
    }
}
