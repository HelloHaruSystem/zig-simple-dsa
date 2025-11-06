const std = @import("std");

pub const Searching = @import("searching.zig").Searching;
pub const Sorting = @import("sorting.zig").Sorting;
pub const TreeAlgos = @import("tree_algorithms.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
