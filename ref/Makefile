CC      := cc
CFLAGS  ?= -pipe -Wall -O3 -fomit-frame-pointer -march=native

LIST    := regex-redux k-nucleotide reverse-complement fannkuch-redux fasta \
           pidigits mandelbrot spectral-norm binary-trees n-body

all: $(addprefix build/,$(LIST))

build/regex-redux: regex-redux.c | build
	$(CC) $(CFLAGS) -fopenmp $< -o $@ -lpcre

build/k-nucleotide: k-nucleotide.c | build
	$(CC) $(CFLAGS) -std=c99 -Iinclude -fopenmp $< -o $@

build/reverse-complement: reverse-complement.c | build
	$(CC) $(CFLAGS) -funroll-loops -fopenmp $< -o $@

build/fannkuch-redux: fannkuch-redux.c | build
	$(CC) $(CFLAGS) $< -o $@

build/fasta: fasta.c | build
	$(CC) $(CFLAGS) -std=c99 -fopenmp -mfpmath=sse -msse3 $< -o $@

build/pidigits: pidigits.c | build
	$(CC) $(CFLAGS) $< -o $@ -lgmp

build/mandelbrot: mandelbrot.c | build
	$(CC) $(CFLAGS) -fopenmp -mno-fma -fno-finite-math-only -mfpmath=sse $< -o $@

build/spectral-norm: spectral-norm.c | build
	$(CC) $(CFLAGS) -fopenmp -mfpmath=sse -msse3 $< -o $@ -lm

build/binary-trees: binary-trees.c | build
	$(CC) $(CFLAGS) $< -o $@ -lm

build/n-body: n-body.c | build
	$(CC) $(CFLAGS) -mfpmath=sse -msse3 $< -o $@ -lm

build:
	@mkdir -p build

clean:
	rm -rf build

.PHONY: build clean
