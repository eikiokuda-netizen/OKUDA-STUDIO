#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/nesasm"
OUT_DIR="$SCRIPT_DIR/bin"
OUT="$OUT_DIR/nesasm"
REPO_URL="https://github.com/ClusterM/nesasm.git"

mkdir -p "$OUT_DIR" "$(dirname -- "$BUILD_DIR")"

if [ ! -d "$BUILD_DIR/.git" ]; then
    rm -rf "$BUILD_DIR"
    git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
else
    git -C "$BUILD_DIR" fetch --depth 1 origin HEAD
    git -C "$BUILD_DIR" reset --hard FETCH_HEAD
fi

make -C "$BUILD_DIR/source" EXEDIR="$OUT_DIR"

echo "ClusterM/nesasm ready: $OUT"
