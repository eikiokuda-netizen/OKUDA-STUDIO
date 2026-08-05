#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/bin"
OUT="$OUT_DIR/nesasm"

mkdir -p "$OUT_DIR"

cat > "$OUT" <<'PY_NESASM'
#!/usr/bin/env python3
"""Small NESASM-compatible builder for this Mapper0 sample project.

It supports the NESASM directives and 6502 addressing modes currently used by
src/main.asm, then writes an iNES ROM next to the source as main.nes.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

COMMENT = re.compile(r";.*$")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ASSIGN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$")

OPCODES = {
    ("sei", "impl"): 0x78,
    ("cld", "impl"): 0xD8,
    ("txs", "impl"): 0x9A,
    ("inx", "impl"): 0xE8,
    ("iny", "impl"): 0xC8,
    ("dex", "impl"): 0xCA,
    ("rts", "impl"): 0x60,
    ("rti", "impl"): 0x40,
    ("ldx", "imm"): 0xA2,
    ("ldy", "imm"): 0xA0,
    ("lda", "imm"): 0xA9,
    ("cpx", "imm"): 0xE0,
    ("stx", "abs"): 0x8E,
    ("sta", "abs"): 0x8D,
    ("bit", "abs"): 0x2C,
    ("jmp", "abs"): 0x4C,
    ("jsr", "abs"): 0x20,
    ("lda", "absx"): 0xBD,
    ("bpl", "rel"): 0x10,
    ("bne", "rel"): 0xD0,
}

class Assembler:
    def __init__(self, source: Path) -> None:
        self.source = source.resolve()
        self.lines: list[tuple[Path, int, str]] = []
        self.labels: dict[str, int] = {}
        self.consts: dict[str, int] = {}
        self.inesprg = 1
        self.ineschr = 0
        self.inesmap = 0
        self.inesmir = 0
        self.pc = 0
        self.bank = 0
        self.out = bytearray([0] * 0x4000)

    def load(self, path: Path) -> None:
        for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            line = COMMENT.sub("", raw).strip()
            if not line:
                continue
            if line.lower().startswith(".include"):
                inc = re.search(r'"([^"]+)"', line)
                if not inc:
                    self.error(path, lineno, "bad .include")
                self.load((path.parent / inc.group(1)).resolve())
                continue
            self.lines.append((path, lineno, line))

    def error(self, path: Path, lineno: int, msg: str) -> None:
        raise SystemExit(f"{path}:{lineno}: {msg}")

    def eval_expr(self, expr: str) -> int:
        expr = expr.strip()
        expr = re.sub(r"\$([0-9A-Fa-f]+)", lambda m: str(int(m.group(1), 16)), expr)
        expr = re.sub(r"%([01]+)", lambda m: str(int(m.group(1), 2)), expr)
        names = {**self.consts, **self.labels}
        for name, value in sorted(names.items(), key=lambda item: -len(item[0])):
            expr = re.sub(rf"\b{re.escape(name)}\b", str(value), expr)
        if re.search(r"[^0-9+\-*/() \t]", expr):
            raise ValueError(expr)
        return int(eval(expr, {"__builtins__": {}}, {}))

    def parse_values(self, args: str) -> list[int]:
        return [self.eval_expr(part) & 0xFF for part in args.split(",") if part.strip()]

    def size_of(self, path: Path, lineno: int, line: str) -> int:
        low = line.lower()
        if low.startswith((".ines", ".bank", ".org")) or ASSIGN.match(line):
            return 0
        if low.startswith(".db"):
            return len([p for p in line[3:].split(",") if p.strip()])
        if low.startswith(".dw"):
            return 2 * len([p for p in line[3:].split(",") if p.strip()])
        op, _, arg = line.partition(" ")
        op = op.lower()
        arg = arg.strip()
        if (op, "impl") in OPCODES:
            return 1
        if arg.startswith("#"):
            return 2
        if op in ("bpl", "bne"):
            return 2
        if arg.endswith(", x") or arg.endswith(",x"):
            return 3
        if (op, "abs") in OPCODES:
            return 3
        self.error(path, lineno, f"unsupported syntax: {line}")
        return 0

    def first_pass(self) -> None:
        self.pc = 0
        for path, lineno, raw in self.lines:
            line = raw
            m = LABEL.match(line)
            if m:
                self.labels[m.group(1)] = self.pc
                line = line[m.end():].strip()
                if not line:
                    continue
            m = ASSIGN.match(line)
            if m:
                self.consts[m.group(1)] = self.eval_expr(m.group(2)) & 0xFFFF
                continue
            low = line.lower()
            if low.startswith(".inesprg"):
                self.inesprg = self.eval_expr(line.split(None, 1)[1])
            elif low.startswith(".ineschr"):
                self.ineschr = self.eval_expr(line.split(None, 1)[1])
            elif low.startswith(".inesmap"):
                self.inesmap = self.eval_expr(line.split(None, 1)[1])
            elif low.startswith(".inesmir"):
                self.inesmir = self.eval_expr(line.split(None, 1)[1])
            elif low.startswith(".bank"):
                self.bank = self.eval_expr(line.split(None, 1)[1])
            elif low.startswith(".org"):
                self.pc = self.eval_expr(line.split(None, 1)[1])
            else:
                self.pc += self.size_of(path, lineno, line)

    def offset(self) -> int:
        if not (0xC000 <= self.pc <= 0xFFFF):
            raise SystemExit(f"PC ${self.pc:04X} outside 16KB PRG ROM window")
        return self.pc - 0xC000

    def emit(self, *values: int) -> None:
        off = self.offset()
        self.out[off:off + len(values)] = bytes(v & 0xFF for v in values)
        self.pc += len(values)

    def second_pass(self) -> None:
        self.pc = 0
        for path, lineno, raw in self.lines:
            line = raw
            m = LABEL.match(line)
            if m:
                line = line[m.end():].strip()
                if not line:
                    continue
            if ASSIGN.match(line):
                continue
            low = line.lower()
            if low.startswith((".inesprg", ".ineschr", ".inesmap", ".inesmir", ".bank")):
                continue
            if low.startswith(".org"):
                self.pc = self.eval_expr(line.split(None, 1)[1])
                continue
            if low.startswith(".db"):
                self.emit(*self.parse_values(line[3:]))
                continue
            if low.startswith(".dw"):
                vals = []
                for part in line[3:].split(","):
                    value = self.eval_expr(part) & 0xFFFF
                    vals.extend([value & 0xFF, value >> 8])
                self.emit(*vals)
                continue
            op, _, arg = line.partition(" ")
            op = op.lower()
            arg = arg.strip()
            try:
                if (op, "impl") in OPCODES:
                    self.emit(OPCODES[(op, "impl")])
                elif arg.startswith("#"):
                    self.emit(OPCODES[(op, "imm")], self.eval_expr(arg[1:]))
                elif op in ("bpl", "bne"):
                    target = self.eval_expr(arg)
                    rel = target - (self.pc + 2)
                    if not -128 <= rel <= 127:
                        self.error(path, lineno, f"branch out of range: {line}")
                    self.emit(OPCODES[(op, "rel")], rel & 0xFF)
                elif arg.endswith(", x") or arg.endswith(",x"):
                    value = self.eval_expr(arg.rsplit(",", 1)[0]) & 0xFFFF
                    self.emit(OPCODES[(op, "absx")], value & 0xFF, value >> 8)
                else:
                    value = self.eval_expr(arg) & 0xFFFF
                    self.emit(OPCODES[(op, "abs")], value & 0xFF, value >> 8)
            except KeyError:
                self.error(path, lineno, f"unsupported addressing mode: {line}")

    def write_rom(self) -> Path:
        flags6 = (self.inesmir & 1) | ((self.inesmap & 0x0F) << 4)
        flags7 = self.inesmap & 0xF0
        header = bytearray(b"NES\x1A")
        header.extend([self.inesprg, self.ineschr, flags6, flags7])
        header.extend([0] * 8)
        rom = header + self.out[: self.inesprg * 0x4000]
        if self.ineschr:
            rom.extend([0] * (self.ineschr * 0x2000))
        output = self.source.with_suffix(".nes")
        output.write_bytes(rom)
        print(f"NESASM-compatible build complete: {output.name}")
        return output

    def run(self) -> None:
        self.load(self.source)
        self.first_pass()
        self.second_pass()
        self.write_rom()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: nesasm.py <source.asm>")
    Assembler(Path(sys.argv[1])).run()
PY_NESASM

chmod +x "$OUT"
echo "NESASM-compatible tool ready: $OUT"
