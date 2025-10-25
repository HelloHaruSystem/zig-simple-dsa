const std = @import("std");

pub const HashMap = @import("hash_map.zig").HashMap;

test {
    std.testing.refAllDeclsRecursive(@This());
}
