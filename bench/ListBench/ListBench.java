public class ListBench {
    static boolean visit = false;
    int intCount;
    int tupleCount;
    int stringCount;
    int checksum;

    String[] strings = {
		"A", "scientific", "truth", "does", "not", "triumph", "by", "convincing", 
		"its", "opponents", "and", "making", "them", "see", "the", "light,", "but", 
		"rather", "because", "its", "opponents", "eventually", "die", "and", "a", 
		"new", "generation", "grows", "up", "that", "is", "familiar", "with", "it.",
		"--Max", "Planck"
    };

    public static void main(String[] args) {
	System.exit(new ListBench().run(args));
    }

    int run(String[] args) {
	if (args.length < 3) {
		System.out.println("Usage: ListBench <intCount> <tupleCount> <stringCount>");
		return 1;
	}
	intCount = Integer.parseInt(args[0]);
	tupleCount = Integer.parseInt(args[1]);
	stringCount = Integer.parseInt(args[2]);

	for (int i = 0; i < 5000; i++) doBench();

	System.out.println(checksum);
	return 0;
    }

    void doBench() {
		List<Integer> intList = null;
		for (int i = 0; i < intCount; i++) {
		    intList = new List<Integer>(i, intList);
		}
		if (visit) for (List<Integer> l = intList; l != null; l = l.tail) {
		    checksum += l.head;
		}

		List<IntPair> tupleList = null;
		for (int i = 0; i < tupleCount; i++) {
		    tupleList = new List<IntPair>(new IntPair(i, i + 13), tupleList);
		}
		if (visit) for (List<IntPair> l = tupleList; l != null; l = l.tail) {
		    checksum += l.head.a;
		}

		List<String> stringList = null;
		for (int i = 0; i < stringCount; i++) {
		    stringList = new List<String>(strings[i % strings.length], stringList);
		}
		if (visit) for (List<String> l = stringList; l != null; l = l.tail) {
		    checksum += l.head.length();
		}
    }
}
// Models a pair of integers (int, int) in Java
class IntPair {
    int a;
    int b;
    IntPair(int a, int b) {
	this.a = a;
	this.b = b;
    }
    public boolean equals(Object o) {
	if (o instanceof IntPair) {
	    IntPair that = (IntPair) o;
	    return this.a == that.a && this.b == that.b;
	}
	return false;
    }
    public int hashCode() {
	return a + (b << 4);
    }
}

class List<T> {
    T head;
    List<T> tail;
    List(T head, List<T> tail) {
	this.head = head;
	this.tail = tail;
    }
}