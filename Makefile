all: \
	build/binary-trees \
	build/fannkuch-redux \
	build/fasta \
	build/mandelbrot \
	build/n-body \
	build/reverse-complement \
	build/spectral-norm

build/binary-trees: src/binary-trees.zig | mkdir
	zig build-exe $< --output $@ --release-fast --library c

build/fannkuch-redux: src/fannkuch-redux.zig | mkdir
	zig build-exe $< --output $@ --release-fast

build/fasta: src/fasta.zig | mkdir
	zig build-exe $< --output $@ --release-fast

build/mandelbrot: src/mandelbrot.zig | mkdir
	zig build-exe $< --output $@ --release-fast

build/n-body: src/n-body.zig | mkdir
	zig build-exe $< --output $@ --release-fast

build/reverse-complement: src/reverse-complement.zig | mkdir
	zig build-exe $< --output $@ --release-fast --library c

build/spectral-norm: src/spectral-norm.zig | mkdir
	zig build-exe $< --output $@ --release-fast

mkdir:
	@mkdir -p build

clean:
	@rm -rf build

.PHONY: mkdir clean