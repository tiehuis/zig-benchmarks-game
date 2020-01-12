const std = @import("std");
const c = @cImport(@cInclude("pcre.h"));

const Regex = struct {
    re: *c.pcre,
    re_ex: *c.pcre_extra,

    pub fn compile(pattern: [*]const u8) !Regex {
        var result: Regex = undefined;

        var re_eo: c_int = undefined;
        var re_e: [*c]const u8 = undefined;

        const re = c.pcre_compile(pattern, 0, &re_e, &re_eo, 0);
        if (re) |ok_re| {
            result.re = ok_re;
        } else {
            return error.FailedToCompileRegex;
        }

        result.re_ex = c.pcre_study(result.re, c.PCRE_STUDY_JIT_COMPILE, &re_e);
        return result;
    }
};

fn substitute(dst: *std.ArrayList(u8), src: []const u8, pattern: [*]const u8, replacement: [*]const u8) !usize {
    var regex = try Regex.compile(pattern);
    dst.shrink(0);

    var pos: c_int = 0;
    var m: [3]c_int = undefined;
    while (c.pcre_exec(regex.re, regex.re_ex, src.ptr, @intCast(c_int, src.len), pos, 0, &m[0], 3) >= 0) : (pos = m[1]) {
        const upos = @intCast(usize, pos);
        const clen = @intCast(usize, m[0]) - upos;
        try dst.appendSlice(src[upos .. upos + clen]);
        try dst.appendSlice(std.mem.toSliceConst(u8, @ptrCast([*:0]const u8, replacement)));
    }

    const upos = @intCast(usize, pos);
    const clen = src.len - upos;
    try dst.appendSlice(src[upos .. upos + clen]);
    return dst.len;
}

fn countMatches(src: []const u8, pattern: [*]const u8) !usize {
    var regex = try Regex.compile(pattern);

    var count: usize = 0;
    var pos: c_int = 0;
    var m: [3]c_int = undefined;
    while (c.pcre_exec(regex.re, regex.re_ex, src.ptr, @intCast(c_int, src.len), pos, 0, &m[0], 3) >= 0) : (pos = m[1]) {
        count += 1;
    }

    return count;
}

const variants = [_][*:0]const u8{
    "agggtaaa|tttaccct",
    "[cgt]gggtaaa|tttaccc[acg]",
    "a[act]ggtaaa|tttacc[agt]t",
    "ag[act]gtaaa|tttac[agt]ct",
    "agg[act]taaa|ttta[agt]cct",
    "aggg[acg]aaa|ttt[cgt]ccct",
    "agggt[cgt]aa|tt[acg]accct",
    "agggta[cgt]a|t[acg]taccct",
    "agggtaa[cgt]|[acg]ttaccct",
};

const subs = [_][*:0]const u8{
    "tHa[Nt]",            "<4>",
    "aND|caN|Ha[DS]|WaS", "<3>",
    "a[NSt]|BY",          "<2>",
    "<[^>]*>",            "|",
    "\\|[^|][^|]*\\|",    "-",
};

pub fn main() !void {
    var allocator = std.heap.c_allocator;

    var stdout_file = std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    const stdout = &stdout_out_stream.stream;

    var stdin_file = std.io.getStdIn();
    var stdin = stdin_file.inStream();

    var seq: [2]std.ArrayList(u8) = undefined;
    seq[1] = std.ArrayList(u8).init(allocator);
    defer seq[1].deinit();

    const input = try stdin.stream.readAllAlloc(allocator, std.math.maxInt(usize));
    const ilen = input.len;
    seq[0] = std.ArrayList(u8).fromOwnedSlice(allocator, input);
    defer seq[0].deinit();

    const clen = try substitute(&seq[1], seq[0].toSliceConst(), ">.*|\n", "");
    for (variants) |variant| {
        try stdout.print("{s} {}\n", .{ variant, countMatches(seq[1].toSliceConst(), variant) });
    }

    var slen: usize = 0;

    var i: usize = 0;
    var flip: usize = 1;
    while (i < subs.len) : (i += 2) {
        slen = try substitute(&seq[1 - flip], seq[flip].toSliceConst(), subs[i], subs[i + 1]);
        flip = 1 - flip;
    }

    try stdout.print("\n{}\n{}\n{}\n", .{ ilen, clen, slen });
}
