const std = @import("std");

pub const Queue = @import("queue.zig").Queue;
pub const Deque = @import("deque.zig").Deque;

test {
    std.testing.refAllDeclsRecursive(@This());
}
