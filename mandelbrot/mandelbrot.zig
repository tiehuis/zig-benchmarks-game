const std = @import("std");
const Float = f32;

pub fn main() !void {
    var stdout_file = try std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(&stdout_file);
    const stdout = &stdout_out_stream.stream;

    const w: usize = 16000;
    const h = w;
    const iterations = 50;
    const limit = 2.0;

    try stdout.print("P4\n{} {}\n", w, h);

    var ba: u8 = 0;
    var bn: u8 = 0;
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const cr = 2.0 * @intToFloat(Float, x) / @intToFloat(Float, w) - 1.5;
            const ci = 2.0 * @intToFloat(Float, y) / @intToFloat(Float, h) - 1.0;

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
                try stdout.print("{c}", ba);
                ba = 0;
                bn = 0;
            } else if (x == w - 1) {
                ba = std.math.shr(u8, ba, 8 - w % 8);
                try stdout.print("{c}", ba);
                ba = 0;
                bn = 0;
            }
        }
    }
}
