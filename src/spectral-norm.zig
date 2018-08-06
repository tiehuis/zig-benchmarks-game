const std = @import("std");

fn eval_a(i: usize, j: usize) f64 {
    return 1.0 / @intToFloat(f64, (i + j) * (i + j + 1) / 2 + i + 1);
}

fn eval_a_times_u(comptime transpose: bool, au: []f64, u: []const f64) void {
    for (au) |*e| {
        e.* = 0;
    }

    var i: usize = 0;
    while (i < au.len) : (i += 1) {
        var j: usize = 0;
        while (j < au.len) : (j += 1) {
            if (transpose) {
                au[i] += eval_a(j, i) * u[j];
            } else {
                au[i] += eval_a(i, j) * u[j];
            }
        }
    }
}

fn eval_ata_times_u(atau: []f64, u: []const f64, scratch: []f64) void {
    std.debug.assert(atau.len == u.len and u.len == scratch.len);

    eval_a_times_u(false, scratch, u);
    eval_a_times_u(true, atau, scratch);
}

var allocator = &std.heap.DirectAllocator.init().allocator;

pub fn main() !void {
    var stdout_file = try std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(&stdout_file);
    const stdout = &stdout_out_stream.stream;

    var args = std.os.args();
    _ = args.skip();
    const n = try std.fmt.parseUnsigned(u64, try args.next(allocator).?, 10);

    var u = try allocator.alloc(f64, n);
    var v = try allocator.alloc(f64, n);
    var scratch = try allocator.alloc(f64, n);

    for (u) |*e| {
        e.* = 1;
    }

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        eval_ata_times_u(v, u, scratch);
        eval_ata_times_u(u, v, scratch);
    }

    var vbv: f64 = 0;
    var vv: f64 = 0;

    var j: usize = 0;
    while (j < n) : (j += 1) {
        vbv += u[i] * v[i];
        vv += v[i] * v[i];
    }

    try stdout.print("{.9}\n", std.math.sqrt(vbv / vv));
}
