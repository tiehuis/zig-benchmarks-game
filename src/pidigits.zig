const std = @import("std");
const c = @cImport(@cInclude("gmp.h"));

var _tmp1: c.mpz_t = undefined;
const tmp1 = &_tmp1[0];

var _tmp2: c.mpz_t = undefined;
const tmp2 = &_tmp2[0];

var _acc: c.mpz_t = undefined;
const acc = &_acc[0];

var _den: c.mpz_t = undefined;
const den = &_den[0];

var _num: c.mpz_t = undefined;
const num = &_num[0];

fn extractDigit(nth: usize) usize {
    c.mpz_mul_ui(tmp1, num, nth);
    c.mpz_add(tmp2, tmp1, acc);
    c.mpz_tdiv_q(tmp1, tmp2, den);

    return @intCast(usize, c.mpz_get_si(tmp1));
}

fn eliminateDigit(d: usize) void {
    c.mpz_submul_ui(acc, den, d);
    c.mpz_mul_ui(acc, acc, 10);
    c.mpz_mul_ui(num, num, 10);
}

fn nextTerm(k: usize) void {
    const k2 = k * 2 + 1;

    c.mpz_addmul_ui(acc, num, 2);
    c.mpz_mul_ui(acc, acc, k2);
    c.mpz_mul_ui(den, den, k2);
    c.mpz_mul_ui(num, num, k);
}

pub fn main() !void {
    var stdout_file = std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    var buffered_stdout = std.io.BufferedOutStream(std.fs.File.OutStream.Error).init(&stdout_out_stream.stream);
    defer _ = buffered_stdout.flush() catch {};
    var stdout = &buffered_stdout.stream;

    var args = std.process.args();
    _ = args.skip();
    const n = try std.fmt.parseUnsigned(usize, try args.next(std.heap.c_allocator).?, 10);

    c.mpz_init(tmp1);
    c.mpz_init(tmp2);
    c.mpz_init_set_ui(acc, 0);
    c.mpz_init_set_ui(den, 1);
    c.mpz_init_set_ui(num, 1);

    var i: usize = 0;
    var k: usize = 0;
    while (i < n) {
        k += 1;
        nextTerm(k);
        if (c.mpz_cmp(num, acc) > 0) {
            continue;
        }

        const d = extractDigit(3);
        if (d != extractDigit(4)) {
            continue;
        }

        try stdout.print("{c}", .{@intCast(u8, '0' + d)});
        i += 1;
        if (i % 10 == 0) {
            try stdout.print("\t:{}\n", .{i});
        }
        eliminateDigit(d);
    }
}
