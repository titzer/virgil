var color = true;
var GREEN=color ? '[0;32m' : '';
var YELLOW=color ? '[0;33m' : '';
var RED=color ? '[0;31m' : '';
var NORM=color ? '[0;00m' : '';
var verbose = 2;
var cmdLineArgs = arguments;  // D8 specific ?
var globalTestRuns = undefined;
var outputDir = "";

function fail(testname, msg) {
    print("##-fail: " + msg);
}

function begin(testname) {
    print("##+" + testname);
}

function pass(testname) {
    print("##-ok");
}

function runTest(testname) {
    begin(testname);
    // 1. Read WASM buffer
    var buffer;
    var wasmfile = testname + ".wasm";
    try {
        buffer = readbuffer(wasmfile);  // D8 specific
    } catch (e) {
        return fail(testname, wasmfile + " file not found");
    }

    // 2. Create WASM module and instance
    var module;
    var instance;
    var main;
    try {
        module = new WebAssembly.Module(buffer);
        instance = new WebAssembly.Instance(module);
        main = instance.exports.main;
    } catch (e) {
        return fail(testname, "" + e);
    }

    // 3. Load test expectations
    globalTestRuns = undefined;  // by convention, overwritten by loaded script
    var expectfile = testname + ".expect.js";
    try {
        load(expectfile);  // D8 specific
    } catch (e) {
        return fail(testname, expectfile + " file not found");
    }

    // 4. Perform the runs
    var i = 0;
    for (run of globalTestRuns) {
        let expect = run[0];
        try  {
            let result = main(...run[1]);
            if (result != expect) throw new Error("expected " + expect + ", but got " + result);
        } catch (e) {
            if (expect == WebAssembly.RuntimeError && e instanceof WebAssembly.RuntimeError) {
                // Successfully caught exception expected to be thrown.
                // TODO: check the specific error thrown.
            } else {
                return fail(testname, "Run " + i + " failed: " + e);
            }
        }
        i++;
    }
    pass(testname);
}

(function mainLoop() {
    var tests = [];
    for (var arg of cmdLineArgs) {
        arg = arg.replace(/[.]v3$/, "");  // strip .v3 extension
        arg = arg.replace(/[.]wasm$/, "");  // strip .wasm extension
        tests.push(arg);
    }
    print("##>" + tests.length);
    for (var i = 0; i < tests.length; i++) {
        runTest(tests[i]);
    }
})();
