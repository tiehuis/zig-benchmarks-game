const std = @import("std");
const c = @cImport(@cInclude("gmp.h"));

var _storage: [5]c.mpz_t = undefined;
const tmp1 = &_storage[0];
const tmp2 = &_storage[1];
const acc = &_storage[2];
const den = &_storage[3];
const num = &_storage[4];

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

var buffer: [256]u8 = undefined;
var fixed_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
var allocator = &fixed_allocator.allocator;

pub fn main() !void {
    var buffered_stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer buffered_stdout.flush() catch unreachable;
    const stdout = buffered_stdout.writer();

    var args = try std.process.argsAlloc(allocator);
    if (args.len < 2) return error.InvalidArguments;

    const n = try std.fmt.parseUnsigned(usize, args[1], 10);

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
