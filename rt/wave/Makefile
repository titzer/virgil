WASM_C_API_DIR := ../../bin/dev/wasm-c-api
WASM_HH := $(WASM_C_API_DIR)/include/wasm.hh
WASM_V8 := $(WASM_C_API_DIR)/out/wasm-v8.o
WAVE=../../bin/dev/wave
COPTS=-fsanitize=address -fsanitize-memory-track-origins -fsanitize-memory-use-after-dtor

all: $(WAVE)

clean:
	rm -f $(WAVE)
	rm -f wave.o

wave.o: wave.cc $(WASM_HH)
	clang++ -std=c++11 -c wave.cc -I$(WASM_C_API_DIR)/include

$(WAVE): wave.o $(WASM_V8)
	clang++ $(COPTS) wave.o -o $(WAVE) $(WASM_C_API_DIR)/out/wasm-bin.o $(WASM_V8) $(WASM_C_API_DIR)/v8/v8/out.gn/x64.release/obj/libv8_monolith.a
