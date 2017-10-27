const std = @import("std");
const printf = std.io.stdout.printf;
const Float = f32;

pub fn main() -> %void {
    const w: usize = 16000;
    const h = w;
    const iterations = 50;
    const limit = 2.0;

    _ = printf("P4\n{} {}\n", w, h);

    var ba: u8 = 0;
    var bn: u8 = 0;
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const cr = 2.0 * Float(x) / Float(w) - 1.5;
            const ci = 2.0 * Float(y) / Float(h) - 1.0;

            var zr: Float = 0.0;
            var zi: Float = 0.0;
            var tr: Float = 0.0;
            var ti: Float = 0.0;

            var i: usize = 0;
            while (i < iterations and (tr + ti <= limit * limit)) : (i += 1) {
                zi = 2.0 * zr * zi + ci;
                zr = tr - ti + cr;
                tr = zr * zr;
                ti = zi * zi;
            }

            ba <<= 1;
            if (tr + ti <= limit * limit) {
                ba |= 1;
            }

            bn += 1;
            if (bn == 8) {
                _ = printf("{c}", ba);
                ba = 0;
                bn = 0;
            } else if (x == w - 1) {
                ba = std.math.shr(u8, ba, 8 - w % 8);
                _ = printf("{c}", ba);
                ba = 0;
                bn = 0;
            }
        }
    }
}
