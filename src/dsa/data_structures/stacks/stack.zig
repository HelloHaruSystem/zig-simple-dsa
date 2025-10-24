const std = @import("std");
const dynamic_array = @import("../arrays/dynamic_array.zig");
const testing = std.testing;

/// Stack data structure
pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        /// Stack is using a dynamic array as the underlying data structure.
        /// The dynamic array owns and is responsible for allocating the memory needed to store new items in the Stack
        _dynamic_array: dynamic_array.DynamicArray(T),

        /// Initializes an empty stack
        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                ._dynamic_array = try dynamic_array.DynamicArray(T).initDefault(allocator),
            };
        }

        /// Frees the memory used by the stack
        pub fn deinit(self: *Self) void {
            self._dynamic_array.deinit();
        }

        /// Pushes a new element on top of the stack
        pub fn push(self: *Self, value: T) !void {
            try self._dynamic_array.append(value);
        }

        /// Pops the last inserted item in the stack
        /// Returning it and removing it from the stack
        /// if the stack is empty this function will return null
        pub fn pop(self: *Self) ?T {
            return self._dynamic_array.pop();
        }

        /// Returns the last inserted item in the stack
        /// without removing it from the stack
        /// If the stack is empty this function will return null
        pub fn peek(self: *const Self) ?T {
            if (self.getSize() == 0) return null;

            const value_pointer = self._dynamic_array.get(self.getSize() - 1);

            if (value_pointer) |value| {
                return value.*;
            }

            return null;
        }

        /// Returns the current size of the stack
        pub fn getSize(self: *const Self) usize {
            return self._dynamic_array.getSize();
        }

        /// returns true if the stack is empty otherwise false
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

test "stack deinit function cleans up memory properly" {
    const allocator = testing.allocator;
    var stack = try Stack(u8).init(allocator);

    try stack.push(16);
    try stack.push(32);

    stack.deinit();
    // If there is a memory leak the testing allocator will fail this test
}

test "push basic functionality" {
    const allocator = testing.allocator;
    var stack = try Stack(i16).init(allocator);
    defer stack.deinit();

    try stack.push(128);
    try stack.push(256);

    try testing.expect(!stack.isEmpty());
    try testing.expect(stack.getSize() == 2);
    try testing.expectEqual(@as(i16, 256), stack.peek().?);
    try testing.expectEqual(@as(i16, 256), stack.pop().?);
    try testing.expectEqual(@as(i16, 128), stack.pop().?);
    try testing.expect(stack.isEmpty());
    try testing.expect(stack.getSize() == 0);
}

test "pop basic functionality" {
    const allocator = testing.allocator;
    var stack = try Stack(f64).init(allocator);
    defer stack.deinit();

    try stack.push(53291.1234);
    try stack.push(-1235.2341);

    try testing.expect(stack.getSize() == 2);
    try testing.expectEqual(@as(f64, -1235.2341), stack.pop().?);
    try testing.expect(stack.getSize() == 1);
    try testing.expectEqual(@as(f64, 53291.1234), stack.pop().?);
    try testing.expect(stack.getSize() == 0);
    try testing.expect(stack.isEmpty());
}

test "pop returns null on empty stack" {
    const allocator = testing.allocator;
    var stack = try Stack(u16).init(allocator);
    defer stack.deinit();

    try testing.expectEqual(null, stack.pop());
}

test "peek returns the value last inserted without removing it from the stack" {
    const allocator = testing.allocator;
    var stack = try Stack(i64).init(allocator);
    defer stack.deinit();

    try stack.push(63120);
    try stack.push(4);

    try testing.expectEqual(@as(i64, 4), stack.peek().?);
    try testing.expectEqual(@as(i64, 4), stack.pop().?);
    try testing.expectEqual(@as(i64, 63120), stack.peek().?);
}

test "peek returns null on an empty stack" {
    const allocator = testing.allocator;
    var stack = try Stack(u64).init(allocator);
    defer stack.deinit();

    try testing.expectEqual(null, stack.peek());
}

test "getSize returns the correct size as a usize" {
    const allocator = testing.allocator;
    var stack = try Stack(u8).init(allocator);
    defer stack.deinit();

    try stack.push(127);
    try stack.push(1);
    try stack.push(72);
    _ = stack.pop();
    _ = stack.pop();

    try testing.expect(stack.getSize() == 1);
}

test "isEmpty basic functionality" {
    const allocator = testing.allocator;
    var stack = try Stack(i16).init(allocator);
    defer stack.deinit();

    try stack.push(-128);

    try testing.expect(!stack.isEmpty());
    try testing.expectEqual(@as(i16, -128), stack.pop().?);
    try testing.expect(stack.isEmpty());
}
