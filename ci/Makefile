
HOSTS = $(shell ../bin/dev/sense_host)

ALL =

ifneq ($(findstring x86-linux,$(HOSTS)),)
ALL += x86-runs
endif

ifneq ($(findstring x86-64-linux,$(HOSTS)),)
ALL += x86-64-runs
endif

ifneq ($(findstring x86-64-darwin,$(HOSTS)),)
ALL += x86-64--darwin-runs
endif

ifneq ($(findstring jar,$(HOSTS)),jar)
ALL += jvm-runs
endif

ifneq ($(shell find ../test/bin -name test-wasm-js@node),)
ALL += wasm-runs
endif

ifneq ($(shell find ../test/bin -name test-wasm-gc-js@node),)
ALL += wasm-gc-runs
endif

all: $(ALL)

check:
	@if grep fail *-out.txt; then echo -n "";  else echo "No failures found."; fi

clean:
	rm -f *-out.txt

veryclean: clean
	rm -rf /tmp/$(USER)/virgil-test

X86_RUNS = x86 x86-wfts

x86-runs: $(X86_RUNS)


X86_64_RUNS = x86-64 x86-64-wfts x86-64-O1 x86-64-O1-wfts x86-64-fp x86-64-fp-wfts \
    x86-64-O2 x86-64-O2-wfts x86-64-uv x86-64-uv-wfts \
    x86-64-uv-O2 x86-64-uv-O2-wfts \

x86-64-runs: $(X86_64_RUNS)


X86_64_DARWIN_RUNS = x86-64-darwin-bootstrap x86-64-darwin-current

x86-64-darwin-runs: $(X86_64_DARWIN_RUNS)


JVM_RUNS = jvm jvm-O2 jvm-uv

jvm-runs: $(JVM_RUNS)


WASM_RUNS = wasm wasm-wfts wasm-O2 wasm-O2-wfts

wasm-runs: $(WASM_RUNS)


WASM_GC_RUNS = wasm-gc wasm-gc-O2 wasm-gc-og wasm-gc-O2-og wasm-gc-rt wasm-gc-O2-rt

wasm-gc-runs: $(WASM_GC_RUNS)


.PHONY: $(ALL) $(X86_RUNS) $(X86_64_RUNS) $(JVM_RUNS) $(WASM_RUNS) $(WASM_GC_RUNS)

#
# x86-linux
#
x86:
	CI_DIR=ci/$@ bash ./linux/build-test-x86.sh       > $@-out.txt 2>&1

x86-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86.sh -wfts > $@-out.txt 2>&1

#
# x86-64-linux
#
x86-64:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh       > $@-out.txt 2>&1

x86-64-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -wfts > $@-out.txt 2>&1

x86-64-O1:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -O1       > $@-out.txt 2>&1

x86-64-O1-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -O1 -wfts > $@-out.txt 2>&1

x86-64-fp:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -rt.fp=true       > $@-out.txt 2>&1

x86-64-fp-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -rt.fp=true -wfts > $@-out.txt 2>&1

x86-64-O2:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -O2       > $@-out.txt 2>&1

x86-64-O2-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -O2 -wfts > $@-out.txt 2>&1

x86-64-uv:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -unbox-variants       > $@-out.txt 2>&1

x86-64-uv-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -unbox-variants -wfts > $@-out.txt 2>&1

x86-64-uv-O2:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -unbox-variants -O2       > $@-out.txt 2>&1

x86-64-uv-O2-wfts:
	CI_DIR=ci/$@ bash ./linux/build-test-x86_64.sh -unbox-variants -O2 -wfts > $@-out.txt 2>&1

#
# x86-64-darwin
#
x86-64-darwin-bootstrap:
	CI_DIR=ci/$@ AENEAS_TEST=bootstrap bash ./macos/build-test-x86_64.sh > $@-out.txt 2>&1

x86-64-darwin-current:
	CI_DIR=ci/$@ AENEAS_TEST=current   bash ./macos/build-test-x86_64.sh > $@-out.txt 2>&1


#
# JVM (wfts always enabled)
#
jvm:
	CI_DIR=ci/$@ bash ./jvm/build-test-jvm.sh     > $@-out.txt 2>&1

jvm-O2:
	CI_DIR=ci/$@ bash ./jvm/build-test-jvm.sh -O2 > $@-out.txt 2>&1

jvm-uv:
	CI_DIR=ci/$@ bash ./jvm/build-test-jvm.sh -unbox-variants > $@-out.txt 2>&1

#
# WASM
#
wasm:
	CI_DIR=ci/$@ bash ./wasm/build-test-wasm.sh       > $@-out.txt 2>&1

wasm-wfts:
	CI_DIR=ci/$@ bash ./wasm/build-test-wasm.sh -wfts > $@-out.txt 2>&1

wasm-O2:
	CI_DIR=ci/$@ bash ./wasm/build-test-wasm.sh -O2       > $@-out.txt 2>&1

wasm-O2-wfts:
	CI_DIR=ci/$@ bash ./wasm/build-test-wasm.sh -O2 -wfts > $@-out.txt 2>&1

#
# WASM GC (wfts always enabled)
#
wasm-gc:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh     > $@-out.txt 2>&1

wasm-gc-O2:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh -O2 > $@-out.txt 2>&1

wasm-gc-og:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh -wasm-gc-one-group     > $@-out.txt 2>&1

wasm-gc-O2-og:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh -O2 -wasm-gc-one-group > $@-out.txt 2>&1

wasm-gc-rt:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh -wasm-gc-use-ref-test     > $@-out.txt 2>&1

wasm-gc-O2-rt:
	CI_DIR=ci/$@ bash ./wasm-gc/build-test-wasm-gc.sh -O2 -wasm-gc-use-ref-test > $@-out.txt 2>&1
