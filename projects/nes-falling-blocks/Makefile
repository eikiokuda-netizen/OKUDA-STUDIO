PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
LOCAL_NESASM := $(abspath $(PROJECT_DIR)/../nes-block-breaker/tools/bin/nesasm)
NESASM ?= $(LOCAL_NESASM)
SOURCE := main.asm
SRC_DIR := src
SRC_ROM := $(SRC_DIR)/main.nes
OUTPUT := build/main.nes

.PHONY: all clean assemble-from-src

all: $(NESASM)
	$(MAKE) -C $(SRC_DIR) -f ../Makefile assemble-from-src
	cp $(SRC_ROM) $(OUTPUT)

$(NESASM):
	$(MAKE) -C ../nes-block-breaker tools/bin/nesasm

assemble-from-src:
	$(NESASM) $(SOURCE)

clean:
	rm -f $(SRC_ROM) $(OUTPUT)
