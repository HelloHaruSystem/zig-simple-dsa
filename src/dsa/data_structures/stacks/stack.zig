const std = @import("std");
const dynamic_array = @import("../arrays/dynamic_array.zig");
const testing = std.testing;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        _dynamic_array: dynamic_array.DynamicArray(T),

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                ._dynamic_array = try dynamic_array.DynamicArray(T).initDefault(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self._dynamic_array.deinit();
        }

        // TODO: push, pop, peek, getSize, isEmpty tests and docs
        pub fn push(self: *Self, value: T) !void {
            try self._dynamic_array.append(value);
        }

        pub fn getSize(self: *const Self) usize {
            return self._dynamic_array.getSize();
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }
    };
}

// tests
test "Stack init function returns an empty stack" {
    const allocator = testing.allocator;
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try testing.expect(stack.getSize() == 0);
    try testing.expect(stack.isEmpty());
}

test "stack deinit function cleans up memory proberly" {
    const allocator = testing.allocator;
    var stack = try Stack(u8).init(allocator);

    try stack.push(16);
    try stack.push(32);

    stack.deinit();
    // If there is a memory leak the testing allocator will fail this test
}
