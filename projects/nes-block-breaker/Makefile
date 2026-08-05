LOCAL_NESASM := tools/bin/nesasm
NESASM ?= $(LOCAL_NESASM)
SOURCE := src/main.asm
OUTPUT := build/main.nes

.PHONY: all clean setup-nesasm

all: $(LOCAL_NESASM)
	$(NESASM) $(SOURCE)
	cp src/main.nes $(OUTPUT)

$(LOCAL_NESASM): tools/setup_nesasm.sh
	./tools/setup_nesasm.sh

setup-nesasm: $(LOCAL_NESASM)

clean:
	rm -f src/main.nes $(OUTPUT)
