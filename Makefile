LIB_UTIL=lib/util/*.v3
LIB_RT=rt/*/*.v3
UTILS=bin/utils/vctags bin/utils/progress bin/utils/nu

all: bootstrap utils

bin/utils/vctags: apps/vctags/* $(LIB_UTIL)
	(cd apps/vctags && v3c-host -output=../../bin/utils/ *.v3 `cat DEPS`)

bin/utils/progress: apps/Progress/* $(LIB_UTIL)
	(cd apps/Progress && v3c-host -program-name=progress -output=../../bin/utils/ *.v3 `cat DEPS`)

bin/utils/nu: apps/NumUtil/* $(LIB_UTIL)
	(cd apps/NumUtil && v3c-host -program-name=nu -output=../../bin/utils/ *.v3 `cat DEPS`)

utils: $(UTILS)

bootstrap: bin/stable/*/* aeneas/src/*/*.v3 $(LIB_UTIL) $(LIB_RT)
	aeneas bootstrap

clean:
	rm -f $(UTILS)
	aeneas clean

.PHONY: utils bootstrap clean
