const std = @import("std");
const Allocator = std.mem.Allocator;
const IncrementingAllocator = std.heap.IncrementingAllocator;
const printf = std.io.stdout.printf;

const TreeNode = struct {
    l: ?&TreeNode,
    r: ?&TreeNode,

    pub fn new(a: &Allocator, l: ?&TreeNode, r: ?&TreeNode) -> &TreeNode {
        var node = %%a.create(TreeNode);
        node.l = l;
        node.r = r;

        node
    }

    pub fn free(self: &TreeNode, a: &Allocator) {
        a.free(self);
    }
};

fn itemCheck(node: &TreeNode) -> usize {
    if (node.l) |left| {
        // either have both nodes or none
        1 + itemCheck(left) + itemCheck(??node.r)
    } else {
        1
    }
}

fn bottomUpTree(a: &Allocator, depth: usize) -> &TreeNode {
    if (depth > 0) {
        TreeNode.new(a, bottomUpTree(a, depth - 1), bottomUpTree(a, depth - 1))
    } else {
        TreeNode.new(a, null, null)
    }
}

pub fn main() -> %void {
    var stdout_file = %return std.io.getStdOut();
    var stdout_out_stream = std.io.FileOutStream.init(&stdout_file);
    const stdout = &stdout_out_stream.stream;

    const n = 21;

    const min_depth: usize = 4;
    const max_depth: usize = n;
    const stretch_depth = max_depth + 1;

    // NOTE: Can we have a variant which grows on demand when needed without up front specification?
    var inc_allocator = %%IncrementingAllocator.init(128 * 1024 * 1024);
    defer inc_allocator.deinit();
    var allocator = &inc_allocator.allocator;

    const stretch_tree = bottomUpTree(allocator, stretch_depth);
    _ = stdout.print("depth {}, check {}\n", stretch_depth, itemCheck(stretch_tree));
    inc_allocator.reset();

    const long_lived_tree = bottomUpTree(allocator, max_depth);
    const marker = inc_allocator.end_index;

    var depth = min_depth;
    while (depth <= max_depth) : (depth += 2) {
        var iterations = usize(std.math.pow(f32, 2, f32(max_depth - depth + min_depth)));
        var check: usize = 0;

        var i: usize = 1;
        while (i <= iterations) : (i += 1) {
            const temp_tree = bottomUpTree(allocator, depth);
            check += itemCheck(temp_tree);
            inc_allocator.end_index = marker;
        }

        _ = stdout.print("{} trees of depth {}, check {}\n", iterations, depth, check);
    }

    _ = stdout.print("long lived tree of depth {}, check {}\n", max_depth, itemCheck(long_lived_tree));
}
