const std = @import("std");

const HashMap = std.AutoHashMap(u64, u32);

inline fn codeForNucleotide(nucleotide: u8) u8 {
    const lookup = [_]u8{ ' ', 0, ' ', 1, 3, ' ', ' ', 2 };
    return lookup[nucleotide & 0x7];
}

inline fn nucleotideForCode(code: u8) u8 {
    return "ACGT"[code & 0x3];
}

fn kvLessThan(_: void, lhs: HashMap.KV, rhs: HashMap.KV) bool {
    if (lhs.value < rhs.value) return false;
    if (lhs.value > rhs.value) return true;
    return lhs.key < rhs.key;
}

fn generateFrequenciesForLength(allocator: *std.mem.Allocator, poly: []const u8, comptime desired_length: usize, output: []u8) !void {
    var hash = HashMap.init(allocator);
    defer hash.deinit();

    const mask = (@as(u64, 1) << (2 * desired_length)) - 1;

    {
        var key: u64 = 0;
        var i: usize = 0;

        while (i < desired_length - 1) : (i += 1) {
            key = ((key << 2) & mask) | poly[i];
        }

        while (i < poly.len) : (i += 1) {
            key = ((key << 2) & mask) | poly[i];
            var entry = try hash.getOrPutValue(key, 0);
            entry.value_ptr.* += 1;
        }
    }

    var list = try allocator.alloc(HashMap.KV, hash.count());
    defer allocator.free(list);

    var i: usize = 0;
    var it = hash.iterator();
    while (it.next()) |entry| {
        list[i] = HashMap.KV{ .key = entry.key_ptr.*, .value = entry.value_ptr.* };
        i += 1;
    }

    std.sort.sort(HashMap.KV, list, {}, kvLessThan);

    var position: usize = 0;
    for (list) |*entry| {
        var olig: [desired_length]u8 = undefined;

        for (olig) |*e, j| {
            const shift = @intCast(u6, 2 * (olig.len - j - 1));
            e.* = nucleotideForCode(@truncate(u8, entry.key >> shift));
        }

        const slice = try std.fmt.bufPrint(
            output[position..],
            "{s} {d:.3}\n",
            .{ olig[0..], 100.0 * @intToFloat(f64, entry.value) / @intToFloat(f64, poly.len - desired_length + 1) },
        );
        position += slice.len;
        output[position] = 0;
    }
}

fn generateCount(allocator: *std.mem.Allocator, poly: []const u8, comptime olig: []const u8, output: []u8) !void {
    var hash = HashMap.init(allocator);
    defer hash.deinit();

    const mask = (@as(u64, 1) << (2 * olig.len)) - 1;

    {
        var key: u64 = 0;
        var i: usize = 0;

        while (i < olig.len - 1) : (i += 1) {
            key = ((key << 2) & mask) | poly[i];
        }

        while (i < poly.len) : (i += 1) {
            key = ((key << 2) & mask) | poly[i];
            var entry = try hash.getOrPutValue(key, 0);
            entry.value_ptr.* += 1;
        }
    }

    {
        var key: u64 = 0;

        for (olig) |_, i| {
            key = ((key << 2) & mask) | codeForNucleotide(olig[i]);
        }

        const count = hash.get(key) orelse 0;
        const slice = try std.fmt.bufPrint(output, "{}\t{s}", .{ count, olig });
        output[slice.len] = 0;
    }
}

pub fn main() !void {
    var allocator = std.heap.c_allocator;

    var buffered_stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer buffered_stdout.flush() catch unreachable;
    const stdout = buffered_stdout.writer();

    var buffered_stdin = std.io.bufferedReader(std.io.getStdIn().reader());
    const stdin = buffered_stdin.reader();

    var buffer: [4096]u8 = undefined;

    while (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |line| {
        if (std.mem.startsWith(u8, line, ">THREE")) {
            break;
        }
    }

    var poly = std.ArrayList(u8).init(allocator);
    defer poly.deinit();

    while (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |line| {
        for (line) |c| {
            try poly.append(codeForNucleotide(c));
        }
    }

    const poly_shrunk = poly.toOwnedSlice();

    const counts = [_]u8{ 1, 2 };
    const entries = [_][]const u8{ "GGT", "GGTA", "GGTATT", "GGTATTTTAATT", "GGTATTTTAATTTATAGT" };

    var output: [counts.len + entries.len][4096]u8 = undefined;

    inline for (counts) |count, i| {
        try generateFrequenciesForLength(allocator, poly_shrunk, count, output[i][0..]);
    }

    inline for (entries) |entry, i| {
        try generateCount(allocator, poly_shrunk, entry, output[i + counts.len][0..]);
    }

    for (output) |entry| {
        const entry_len = std.mem.indexOfScalarPos(u8, entry[0..], 0, 0) orelse unreachable;
        _ = try stdout.print("{s}\n", .{entry[0..entry_len]});
    }
}
