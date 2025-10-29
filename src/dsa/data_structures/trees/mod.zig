const std = @import("std");

pub const BinarySearchTree = @import("binary_search_tree.zig").BinarySearchTree;

test {
    std.testing.refAllDeclsRecursive(@This());
}
