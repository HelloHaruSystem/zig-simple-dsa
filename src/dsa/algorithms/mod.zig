const std = @import("std");

pub const Searching = @import("searching.zig").Searching;
pub const Sorting = @import("sorting.zig").Sorting;

test {
    std.testing.refAllDeclsRecursive(@This());
}
