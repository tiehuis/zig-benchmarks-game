const std = @import("std");

fn tolower(c: usize) usize {
    return if (c -% 'A' < 26) c | 32 else c;
}

fn toupper(c: usize) usize {
    return if (c -% 'a' < 26) c & 0x5f else c;
}

const pairs = "ATCGGCTAUAMKRYWWSSYRKMVBHDDHBVNN\n\n";
const table = comptime block: {
    var t: [128]u8 = undefined;

    var i: usize = 0;
    while (i < pairs.len) : (i += 2) {
        t[toupper(pairs[i])] = pairs[i + 1];
        t[tolower(pairs[i])] = pairs[i + 1];
    }

    break :block t;
};

fn process(buf: []u8, ifrom: usize, ito: usize) void {
    var from = ifrom + std.mem.indexOfScalar(u8, buf[ifrom..], '\n').? + 1;
    var to = ito;

    const len = to - from;
    const off = 60 - (len % 61);

    if (off != 0) {
        var m = from + 60 - off;
        while (m < to) : (m += 61) {
            // memmove(m + 1, m, off);
            var i: usize = 0;
            var t = buf[m];
            while (i < off) : (i += 1) {
                std.mem.swap(u8, &buf[m + 1 + i], &t);
            }

            buf[m] = '\n';
        }
    }

    to -= 1;
    while (from <= to) : ({
        from += 1;
        to -= 1;
    }) {
        const c = table[buf[from]];
        buf[from] = table[buf[to]];
        buf[to] = c;
    }
}

var allocator = std.heap.c_allocator;

pub fn main() !void {
    var stdout_file = try std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(stdout_file);
    var stdout = &stdout_out_stream.stream;

    var stdin_file = try std.io.getStdIn();
    var stdin = std.io.FileInStream.init(stdin_file);

    const buf = try stdin.stream.readAllAlloc(allocator, @maxValue(usize));
    defer allocator.free(buf);

    var to = buf.len - 1;
    while (true) {
        const from = std.mem.lastIndexOfScalar(u8, buf[0..to], '>').?;
        process(buf, from, to);

        if (from == 0) {
            break;
        }

        to = from - 1;
    }

    try stdout.write(buf);
}
