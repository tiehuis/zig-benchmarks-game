const std = @import("std");
const OutStream = std.io.OutStream;
const File = std.fs.File;

const max_line_length = 60;

const im = 139968;
const ia = 3877;
const ic = 29573;
var seed: u32 = 42;
fn nextRandom(max: f64) f64 {
    seed = (seed * ia + ic) % im;
    return max * @intToFloat(f64, seed) / @intToFloat(f64, im);
}

const AminoAcid = struct {
    l: u8,
    p: f64,
};

fn repeatAndWrap(out: *OutStream(File.WriteError), comptime sequence: []const u8, count: usize) void {
    var padded_sequence: [sequence.len + max_line_length]u8 = undefined;
    for (padded_sequence) |*e, i| {
        e.* = sequence[i % sequence.len];
    }

    var off: usize = 0;
    var idx: usize = 0;
    while (idx < count) {
        const rem = count - idx;
        const line_length = std.math.min(max_line_length, rem);

        _ = out.write(padded_sequence[off .. off + line_length]) catch {};
        _ = out.writeByte('\n') catch {};

        off += line_length;
        if (off > sequence.len) {
            off -= sequence.len;
        }
        idx += line_length;
    }
}

fn generateAndWrap(out: *OutStream(File.WriteError), comptime nucleotides: []const AminoAcid, count: usize) void {
    var cum_prob: f64 = 0;
    var cum_prob_total: [nucleotides.len]f64 = undefined;
    for (nucleotides) |n, i| {
        cum_prob += n.p;
        cum_prob_total[i] = cum_prob * im;
    }

    var line: [max_line_length + 1]u8 = undefined;
    line[max_line_length] = '\n';

    var idx: usize = 0;
    while (idx < count) {
        const rem = count - idx;
        const line_length = std.math.min(max_line_length, rem);

        for (line[0..line_length]) |*col| {
            const r = nextRandom(im);

            var c: usize = 0;
            for (cum_prob_total) |n| {
                if (n <= r) {
                    c += 1;
                }
            }

            col.* = nucleotides[c].l;
        }

        line[line_length] = '\n';
        _ = out.write(line[0 .. line_length + 1]) catch {};
        idx += line_length;
    }
}

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
    const n = try std.fmt.parseUnsigned(u64, try args.next(allocator).?, 10);

    const homo_sapiens_alu = "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACCTGAGGTC" ++
        "AGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAATACAAAAATTAGCCGGGCG" ++
        "TGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGCGG" ++
        "AGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";
    try stdout.write(">ONE Homo sapiens alu\n");
    repeatAndWrap(stdout, homo_sapiens_alu, 2 * n);

    const iub_nucleotide_info = [_]AminoAcid{
        AminoAcid{ .l = 'a', .p = 0.27 },
        AminoAcid{ .l = 'c', .p = 0.12 },
        AminoAcid{ .l = 'g', .p = 0.12 },
        AminoAcid{ .l = 't', .p = 0.27 },
        AminoAcid{ .l = 'B', .p = 0.02 },
        AminoAcid{ .l = 'D', .p = 0.02 },
        AminoAcid{ .l = 'H', .p = 0.02 },
        AminoAcid{ .l = 'K', .p = 0.02 },
        AminoAcid{ .l = 'M', .p = 0.02 },
        AminoAcid{ .l = 'N', .p = 0.02 },
        AminoAcid{ .l = 'R', .p = 0.02 },
        AminoAcid{ .l = 'S', .p = 0.02 },
        AminoAcid{ .l = 'V', .p = 0.02 },
        AminoAcid{ .l = 'W', .p = 0.02 },
        AminoAcid{ .l = 'Y', .p = 0.02 },
    };
    try stdout.write(">TWO IUB ambiguity codes\n");
    generateAndWrap(stdout, &iub_nucleotide_info, 3 * n);

    const homo_sapien_nucleotide_info = [_]AminoAcid{
        AminoAcid{ .l = 'a', .p = 0.3029549426680 },
        AminoAcid{ .l = 'c', .p = 0.1979883004921 },
        AminoAcid{ .l = 'g', .p = 0.1975473066391 },
        AminoAcid{ .l = 't', .p = 0.3015094502008 },
    };
    try stdout.write(">THREE Homo sapiens frequency\n");
    generateAndWrap(stdout, &homo_sapien_nucleotide_info, 5 * n);
}
