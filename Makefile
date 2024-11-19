AENEAS_SOURCE=aeneas/src/*/*.v3
LIB_UTIL=lib/util/*.v3
LIB_ASM=lib/asm/*/*.v3
LIB_RT=rt/*/*.v3
UTILS=bin/utils/vctags bin/utils/progress bin/utils/nu bin/utils/np

all: bootstrap utils TAGS

bin/utils/vctags: bootstrap apps/vctags/* $(LIB_UTIL)
	(cd apps/vctags && v3c-host -output=../../bin/utils/ *.v3 `cat DEPS`)

bin/utils/progress: bootstrap apps/Progress/* $(LIB_UTIL)
	(cd apps/Progress && v3c-host -program-name=progress -output=../../bin/utils/ *.v3 `cat DEPS`)

bin/utils/nu: bootstrap apps/NumUtil/* $(LIB_UTIL)
	(cd apps/NumUtil && v3c-host -program-name=nu -output=../../bin/utils/ *.v3 `cat DEPS`)

bin/utils/np: bootstrap apps/NumParse/* $(LIB_UTIL)
	(cd apps/NumParse && v3c-host -program-name=np -output=../../bin/utils/ *.v3 `cat DEPS`)

utils: $(UTILS)

bootstrap: bin/stable/*/* $(AENEAS_SOURCE) $(LIB_UTIL) $(LIB_RT) $(LIB_ASM)
	bin/dev/aeneas bootstrap

clean:
	rm -f TAGS $(UTILS)
	bin/dev/aeneas clean

stable: bin/stable/*/* $(AENEAS_SOURCE) $(LIB_UTIL) $(LIB_RT) $(LIB_ASM)
	V3C_OPTS=-redef-field=Debug.UNSTABLE=false bin/dev/aeneas bootstrap

TAGS: $(AENEAS_SOURCE) $(LIB_UTIL) $(LIB_RT) bin/utils/vctags
	bin/dev/aeneas tags

.PHONY: utils bootstrap clean stable
