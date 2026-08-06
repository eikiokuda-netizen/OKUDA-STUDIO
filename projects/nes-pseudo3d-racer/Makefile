LOCAL_NESASM := tools/bin/nesasm
NESASM ?= $(LOCAL_NESASM)
SRC_DIR := src
SOURCE := main.asm
OUTPUT := build/main.nes
SRC_ROM := $(SRC_DIR)/main.nes

.PHONY: all clean setup-nesasm assemble-from-src

all: $(LOCAL_NESASM) build
	$(MAKE) -C $(SRC_DIR) -f ../Makefile assemble-from-src NESASM=../$(NESASM)
	cp $(SRC_ROM) $(OUTPUT)

build:
	mkdir -p build

$(LOCAL_NESASM): tools/setup_nesasm.sh
	./tools/setup_nesasm.sh

setup-nesasm: $(LOCAL_NESASM)

assemble-from-src:
	$(NESASM) $(SOURCE)

clean:
	rm -f $(SRC_ROM) $(OUTPUT) src/main.fns src/main.lst
