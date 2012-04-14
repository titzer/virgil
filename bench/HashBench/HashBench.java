public class HashBench {
    int intCount;
    int tupleCount;
    int objCount;
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
	System.exit(new HashBench().run(args));
    }

    int run(String[] args) {
	if (args.length < 4) {
		System.out.println("Usage: HashBench <intCount> <tupleCount> <objCount> <stringCount>");
		return 1;
	}
	intCount = Integer.parseInt(args[0]);
	tupleCount = Integer.parseInt(args[1]);
	objCount = Integer.parseInt(args[2]);
	stringCount = Integer.parseInt(args[3]);

	for (int i = 0; i < 10; i++) doBench();

	System.out.println(checksum);
	return 0;
    }

    void doBench() {
		// benchmark int-key map
		HashMap<Integer, Integer> intMap = new HashMap<Integer, Integer>(defaultHash(), defaultEqual());
		for (int i = 0; i < intCount; i++) {
			intMap.set(Random.random(500), i + 3);
		}
		doGets(intMap, intCount * 2);

		// benchmark tuple-key map
		HashMap<IntPair, Integer> tupleMap = new HashMap<IntPair, Integer>(defaultHash(), defaultEqual());
		for (int i = 0; i < tupleCount; i++) {
			int x = Random.random(50), y = Random.random(10);
			tupleMap.set(new IntPair(x, y), i + 4);
		}
		doGets(tupleMap, tupleCount * 2);

		// benchmark object-key map
		HashMap<DemoKey, Integer> objMap = new HashMap<DemoKey, Integer>(defaultHash(), defaultEqual());
		for (int i = 0; i < objCount; i++) {
			objMap.set(new DemoKey(strings[i % strings.length], Random.random(16)), i + 5);
		}
		doGets(objMap, objCount * 2);

		// benchmark string-key map
		HashMap<String, Integer> stringMap = new HashMap<String, Integer>(stringHash, stringEqual);
		for (int i = 0; i < stringCount; i++) {
			stringMap.set(strings[i % strings.length], i + 6);
		}
		doGets(stringMap, stringCount * 2);
    }

    <K> void doGets(HashMap<K, Integer> map, int count) {
		if (count == 0) return;
		K[] keys = map.keys();
		System.out.print("gets ");
		System.out.print(keys.length);
		System.out.print(" keys\n");
		for (int i = 0; i < count; i++) {
			checksum = checksum + map.get(keys[Random.random(keys.length)]);
		}
    }

    static final EqualFunction<Integer> intEqual = defaultEqual();
    static final HashFunction<Integer> intHash = defaultHash();

    static final EqualFunction<String> stringEqual = new EqualFunction<String>() {
	boolean apply(String a, String b) {
		if (a == b) return true;
		if (a.length() != b.length()) return false;
		for (int i = 0; i < a.length(); i++) {
			if (a.charAt(i) != b.charAt(i)) return false;
		}
		return true;
	}
    };

    static final HashFunction<String> stringHash = new HashFunction<String>() {
	int apply(String str) {
		int hashval = str.length();
		for (int i = 0; i < str.length(); i++) hashval = hashval * 31 + str.charAt(i);
		return hashval;
	}
    };

    static <T> EqualFunction<T> defaultEqual() {
	return new EqualFunction<T>() {
		boolean apply(T a, T b) {
		    return a.equals(b);
		}
	};
    }

    static <T> HashFunction<T> defaultHash() {
	return new HashFunction<T>() {
		int apply(T val) {
		    return val.hashCode();
		}
	};
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
// Internal data structure needed by HashMap to represent chained buckets.
class Bucket<K, V> {
    K key;
    V val;
    Bucket<K, V> next;
    Bucket(K key, V val, Bucket<K, V> next) {
	this.key = key;
	this.val = val;
	this.next = next;
    }
}
// Models a hash function in Java.
abstract class HashFunction<K> {
    abstract int apply(K key);
}
// Models an equal function in Java.
abstract class EqualFunction<K> {
    abstract boolean apply(K k1, K k2);
}
class HashMap<K, V> {
    HashFunction<K> hash;
    EqualFunction<K> equals;	// user-supplied equality method
    Bucket<K, V>[] table;	// lazily allocated table
    HashMap(HashFunction hash, EqualFunction equals) {
	this.hash = hash;
	this.equals = equals;
    }

    // get the value for the given key, default if not found
	V get(K key) {
		if (table == null) return null; // empty table
		// hash and do bucket search
		for (Bucket<K, V> bucket = table[dohash(key)]; bucket != null; bucket = bucket.next) {
			if (bucket.key == key || equals.apply(bucket.key, key)) {
				return bucket.val;
			}
		}
		return null;
	}
	// insert or overwrite the value for the given key
	void set(K key, V val) {
		if (table == null) {
			// table not yet allocated,create
		    table = (Bucket<K, V>[]) new Bucket[11];
			insert(new Bucket<K, V>(key, val, null));
			return;
		}
		// hash and search the table
		int hashval = dohash(key), i = 0;
		for (Bucket<K, V> bucket = table[hashval]; bucket != null; bucket = bucket.next) {
			if (equals.apply(bucket.key, key)) {
				bucket.val = val;
				return;
			}
			i++;
		}
		// insert into table
		table[hashval] = new Bucket<K, V>(key, val, table[hashval]);
		if (i > 4 && table.length < 1001) balance(); // rebalance if chain too long
	}
	// get an array of all the keys
	K[] keys() {
		int count = 0;
		for (Bucket<K, V> b : table) {
			for (Bucket<K, V> bucket = b; bucket != null; bucket = bucket.next) count++;
		}
		K[] array = (K[]) new Object[count];
		int i = 0;
		for (Bucket<K, V> b : table) {
			for (Bucket<K, V> bucket = b; bucket != null; bucket = bucket.next) array[i++] = bucket.key;
		}
		return array;
	}
	private void insert(Bucket<K, V> bucket) {
		int hashval = dohash(bucket.key);
		bucket.next = table[hashval];
		table[hashval] = bucket;
	}
	private int dohash(K key) {
		return (0x7FFFFFFF & hash.apply(key)) % table.length;
	}
	private void balance() {
	    Bucket<K, V>[] old = table;
       	int nlen = table.length * 3 + 1;
	table = (Bucket<K, V>[]) new Bucket[nlen];
		for (int i = 0; i < old.length; i++) {
		    for (Bucket<K, V> b = old[i]; b != null; b = b.next) {
				int hashval = dohash(b.key);
				table[hashval] = new Bucket<K, V>(b.key, b.val, table[hashval]);
			}
		}
	}
}
// A demo class that is used as a key in a hashmap
class DemoKey {
    String a;
    int b;
    int hash;
    DemoKey(String a, int b) {
	this.hash = HashBench.stringHash.apply(a) + b;
    }
    public boolean equals(Object o) {
	if (o instanceof DemoKey) {
	    DemoKey that = (DemoKey) o;
	    return HashBench.stringEqual.apply(this.a, that.a) && this.b == that.b;
	}
	return false;
    }
    public int hashCode() {
	return hash;
    }
}
class Random {
	static int seed = 121013;

	// return a pseudo-random number
	static int random(int max) {
		return random2(max, 0);
	}
	// return a pseudo-random number with an extra source of entropy
	static int random2(int max, int extra) {
		seed = seed * 1664525 + 1013904223 + extra;  // multiplicative random
		seed = seed ^ (seed >>> 16) ^ (seed >>> 24); // XOR in some higher bits
		return (seed & 2147483647) % max;    // limit to max
	}
}