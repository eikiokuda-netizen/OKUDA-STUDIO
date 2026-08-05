LOCAL_NESASM := ../tools/bin/nesasm
NESASM ?= $(LOCAL_NESASM)
SOURCE := main.asm
OUTPUT := build/main.nes
SRC_DIR := src
SRC_ROM := $(SRC_DIR)/main.nes

.PHONY: all clean setup-nesasm assemble-from-src

all: tools/bin/nesasm
	$(MAKE) -C $(SRC_DIR) -f ../Makefile assemble-from-src
	cp $(SRC_ROM) $(OUTPUT)

tools/bin/nesasm: tools/setup_nesasm.sh
	./tools/setup_nesasm.sh

setup-nesasm: tools/bin/nesasm

assemble-from-src:
	$(NESASM) $(SOURCE)

clean:
	rm -f $(SRC_ROM) $(OUTPUT)
