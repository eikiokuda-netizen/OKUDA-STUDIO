NESASM := /d/Tools/nesasm/nesasm.exe
SOURCE := src/main.asm
OUTPUT := build/main.nes

.PHONY: all clean

all:
	cd src && $(NESASM) main.asm
	cp src/main.nes $(OUTPUT)

clean:
	rm -f src/main.nes $(OUTPUT)