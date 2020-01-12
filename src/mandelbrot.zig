const std = @import("std");

var buffer: [32]u8 = undefined;
var fixed_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
var allocator = &fixed_allocator.allocator;

pub fn main() !void {
    var stdout_file = std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    var buffered_stdout = std.io.BufferedOutStream(std.fs.File.OutStream.Error).init(&stdout_out_stream.stream);
    defer _ = buffered_stdout.flush() catch {};
    var stdout = &buffered_stdout.stream;

    var args = std.process.args();
    _ = args.skip();
    const w = try std.fmt.parseUnsigned(usize, try args.next(allocator).?, 10);
    const h = w;

    const iterations = 50;
    const limit = 2.0;

    try stdout.print("P4\n{} {}\n", .{ w, h });

    var ba: u8 = 0;
    var bn: u8 = 0;
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const cr = 2.0 * @intToFloat(f64, x) / @intToFloat(f64, w) - 1.5;
            const ci = 2.0 * @intToFloat(f64, y) / @intToFloat(f64, h) - 1.0;

            var zr: f64 = 0.0;
            var zi: f64 = 0.0;
            var tr: f64 = 0.0;
            var ti: f64 = 0.0;

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
                try stdout.print("{c}", .{ba});
                ba = 0;
                bn = 0;
            } else if (x == w - 1) {
                ba = std.math.shr(u8, ba, 8 - w % 8);
                try stdout.print("{c}", .{ba});
                ba = 0;
                bn = 0;
            }
        }
    }
}
