#!/bin/bash -eu

OUT_DIR="out"
mkdir -p $OUT_DIR
odin build src -out:$OUT_DIR/out.bin -debug
echo "Build created in ${OUT_DIR}"

