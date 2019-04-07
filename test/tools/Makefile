BIN=output-processor
OPTS=-heap-size=100m

all: $(BIN)-x86-linux $(BIN)-x86-darwin

$(BIN)-x86-linux: OutputProcessor.v3
	v3c-x86-linux -output=/tmp $(OPTS) OutputProcessor.v3
	mv /tmp/OutputProcessor $(BIN)-x86-linux

$(BIN)-x86-darwin: OutputProcessor.v3
	v3c-x86-darwin -output=/tmp $(OPTS) OutputProcessor.v3
	mv /tmp/OutputProcessor $(BIN)-x86-darwin
