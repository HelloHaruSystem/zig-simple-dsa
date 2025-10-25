const std = @import("std");

pub const Stack = @import("stack.zig").Stack;

test {
    std.testing.refAllDeclsRecursive(@This());
}
