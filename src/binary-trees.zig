const std = @import("std");
const Allocator = std.mem.Allocator;

const TreeNode = struct {
    l: ?*TreeNode,
    r: ?*TreeNode,

    pub fn new(a: *Allocator, l: ?*TreeNode, r: ?*TreeNode) !*TreeNode {
        var node = try a.create(TreeNode);
        node.l = l;
        node.r = r;
        return node;
    }

    pub fn free(self: *TreeNode, a: *Allocator) void {
        a.destroy(self);
    }
};

fn itemCheck(node: *TreeNode) usize {
    if (node.l) |left| {
        // either have both nodes or none
        return 1 + itemCheck(left) + itemCheck(node.r.?);
    } else {
        return 1;
    }
}

fn bottomUpTree(a: *Allocator, depth: usize) Allocator.Error!*TreeNode {
    if (depth > 0) {
        const left = try bottomUpTree(a, depth - 1);
        const right = try bottomUpTree(a, depth - 1);

        return try TreeNode.new(a, left, right);
    } else {
        return try TreeNode.new(a, null, null);
    }
}

fn deleteTree(a: *Allocator, node: *TreeNode) void {
    if (node.l) |left| {
        // either have both nodes or none
        deleteTree(a, left);
        deleteTree(a, node.r.?);
    }

    a.destroy(node);
}

var allocator = std.heap.c_allocator;

pub fn main() !void {
    var stdout_file = try std.io.getStdOut();
    var stdout_out_stream = stdout_file.outStream();
    const stdout = &stdout_out_stream.stream;

    var args = std.os.args();
    _ = args.skip();
    const n = try std.fmt.parseUnsigned(u8, try args.next(allocator).?, 10);

    const min_depth: usize = 4;
    const max_depth: usize = n;
    const stretch_depth = max_depth + 1;

    const stretch_tree = try bottomUpTree(allocator, stretch_depth);
    try stdout.print("depth {}, check {}\n", stretch_depth, itemCheck(stretch_tree));
    deleteTree(allocator, stretch_tree);

    const long_lived_tree = try bottomUpTree(allocator, max_depth);
    var depth = min_depth;
    while (depth <= max_depth) : (depth += 2) {
        var iterations = @floatToInt(usize, std.math.pow(f32, 2, @intToFloat(f32, max_depth - depth + min_depth)));
        var check: usize = 0;

        var i: usize = 1;
        while (i <= iterations) : (i += 1) {
            const temp_tree = try bottomUpTree(allocator, depth);
            check += itemCheck(temp_tree);
            deleteTree(allocator, temp_tree);
        }

        try stdout.print("{} trees of depth {}, check {}\n", iterations, depth, check);
    }

    try stdout.print("long lived tree of depth {}, check {}\n", max_depth, itemCheck(long_lived_tree));
    deleteTree(allocator, long_lived_tree);
}
