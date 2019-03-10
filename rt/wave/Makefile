all: wave

WASM_C_API_DIR := /project/titzer/wasm-c-api/
WASM_HH := $(WASM_C_API_DIR)/include/wasm.hh
WASM_V8 := $(WASM_C_API_DIR)/out/wasm-v8.o

wave.o: wave.cc $(WASM_HH)
	clang++ -std=c++11 -c wave.cc -I$(WASM_C_API_DIR)/include

wave: wave.o $(WASM_V8)
	ld -o wave wave.o $(WASM_V8)
