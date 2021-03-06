# Synthesis #

Let's take a look at some real code and see how the features of Virgil have their expression in real programs.

```
// Internal data structure needed by HashMap to represent chained buckets.
class Bucket<K, V> {
    def key: K;
    var val: V;
    var next: Bucket<K, V>;
    new(key, val, next) { }
}
// A general-purpose HashMap implementation.
// For maximum reusability, this implementation accepts the hash and equality functions
// as delegates, and thus can map any key type to any value type.
class HashMap<K, V> {
    def hash: K -> int;		// user-supplied hash function
    def equals: (K, K) -> bool;	// user-supplied equality method
    var table: Array<Bucket<K, V>>;	// lazily allocated table
    new(hash, equals) { }

    // get the value for the given key, default if not found
    def get(key: K) -> V {
        var none: V;
        if (table == null) return none; // empty table
        // hash and do bucket search
        for (bucket = table[dohash(key)]; bucket != null; bucket = bucket.next) {
            if (bucket.key == key || equals(bucket.key, key)) {
                return bucket.val;
            }
        }
        return none;
    }
    // insert or overwrite the value for the given key
    def set(key: K, val: V) {
        if (table == null) {
            // table not yet allocated,create
            table = Array.new(11);
            insert(Bucket.new(key, val, null));
            return;
        }
        // hash and search the table
        var hashval = dohash(key), i = 0;
        for (bucket = table[hashval]; bucket != null; bucket = bucket.next) {
            if (equals(bucket.key, key)) {
                bucket.val = val;
                return;
            }
            i++;
        }
        // insert into table
        table[hashval] = Bucket.new(key, val, table[hashval]);
        if (i > 4 && table.length < 1001) balance(); // rebalance if chain too long
    }
    // apply the given function to every (key, value) pair in the table
    def apply(func: (K, V) -> void) {
        if (table == null) return;
        for (b in table) {
            for (bucket = b; bucket != null; bucket = bucket.next) {
                func(bucket.key, bucket.val);
            }
        }
    }
    private def insert(bucket: Bucket<K, V>) {
        var hashval = dohash(bucket.key);
        bucket.next = table[hashval];
        table[hashval] = bucket;
    }
    private def dohash(key: K) -> int {
        return (0x7FFFFFFF & hash(key)) % table.length;
    }
    private def balance() {
        var old = table, nlen = table.length * 3 + 1;
        table = Array.new(nlen);
        for (i = 0; i < old.length; i++) {
            for (b = old(i); b != null; b = b.next) {
                var hashval = dohash(b.key);
                table[hashval] = Bucket.new(b.key, b.val, table[hashval]);
            }
        }
    }
}
// A demo class that is used as a key in a hashmap
class DemoKey(a: string, b: int) {
    def hash() -> int {
        return stringHash(a) + b;
    }
    def equal(that: DemoKey) -> bool {
        return stringEqual(this.a, that.a) && this.b == that.b;
    }
}
// a hashmap for integers that uses the identity hash
var x = HashMap<int, byte>.new(int.!<int>, int.==);

// a hashmap for bytes that uses the identity hash
var y = HashMap<byte, string>.new(int.!<byte>, byte.==);

// a hashmap for strings that uses custom hash and equality functions
var z = HashMap<string, bool>.new(stringHash, stringEqual);

// a hashmap for demo keys that uses custom hash and equality functions
var w = HashMap<DemoKey, bool>.new(DemoKey.hash, DemoKey.equal);

def stringEqual(a: string, b: string) -> bool {
    if (a == b) return true;
    if (a.length != b.length) return false;
    for (i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
    }
    return true;
}
def stringHash(str: string) -> int {
    var hashval = str.length;
    for (c in str) hashval = hashval * 31 + c;
    return hashval;
}
```
