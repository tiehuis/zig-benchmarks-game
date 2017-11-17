// NOTE: This segfaults on release-fast and release-safe modes.

const std = @import("std");

const Float = f32;
const n = 5500;

fn eval_a(i: usize, j: usize) -> Float {
    1.0 / Float((i + j) * (i + j + 1) / 2 + i + 1)
}

fn eval_a_times_u(comptime transpose: bool, au: []Float, u: []const Float) {
    for (au) |*e| {
        *e = 0;
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

fn eval_ata_times_u(atau: []Float, u: []const Float) {
    var v: [n]Float = undefined;

    eval_a_times_u(false, v[0..], u);
    eval_a_times_u(true, atau, v[0..]);
}

pub fn main() -> %void {
    var stdout_file = %return std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(&stdout_file);
    const stdout = &stdout_out_stream.stream;

    var u: [n]Float = undefined;
    var v: [n]Float = undefined;

    for (u) |*e| {
        *e = 1;
    }

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        eval_ata_times_u(v[0..], u[0..]);
        eval_ata_times_u(u[0..], v[0..]);
    }

    var vbv: Float = 0;
    var vv: Float = 0;

    var j: usize = 0;
    while (j < n) : (j += 1) {
        vbv += u[i] * v[i];
        vv += v[i] * v[i];
    }

    _ = stdout.print("{}\n", std.math.sqrt(vbv / vv));
}
