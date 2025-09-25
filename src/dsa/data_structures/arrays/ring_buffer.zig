const std = @import("std");
const testing = std.testing;

/// Ring buffer aka Circular buffer
pub fn RingBuffer(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        buffer: []T,
        write_index: usize,
        read_index: usize,
        size: usize,

        /// Initialize an empty ring buffer with the given capacity
        pub fn init(allocator: std.mem.Allocator, buffer_capacity: usize) !Self {
            return Self{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, buffer_capacity),
                .write_index = 0,
                .read_index = 0,
                .size = 0,
            };
        }

        /// Frees the memory used by the ring buffer
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buffer);
        }

        /// Check if the ring buffer is empty
        pub fn isEmpty(self: *Self) bool {
            return self.size == 0;
        }

        /// Check if the ring buffer is full
        pub fn isFull(self: *Self) bool {
            return self.size == self.buffer.len;
        }

        /// Push a new element unto the ring buffer
        /// returns null if push doesn't overrite any existing values
        /// returns the value it overrites in case the ring buffer is full
        pub fn push(self: *Self, data: T) ?T {
            var overwritten: ?T = null;
            if (self.isFull()) {
                overwritten = self.buffer[self.write_index];
                self.read_index = (self.read_index + 1) % self.buffer.len;
            } else {
                self.size += 1;
            }

            self.buffer[self.write_index] = data;
            self.write_index = (self.write_index + 1) % self.buffer.len;

            return overwritten;
        }

        /// Follows the first in first out principle
        /// returns and removes the first added item in the ring buffer
        pub fn pop(self: *Self) ?T {
            if (self.size == 0) return null;

            const data = self.buffer[self.read_index];
            self.read_index = (self.read_index + 1) % self.buffer.len;
            self.size -= 1;

            return data;
        }

        /// Follows the first in first out principle
        /// returns the first added item in the ring buffer
        /// without removing it
        pub fn peek(self: *Self) ?T {
            if (self.size == 0) return null;

            return self.buffer[self.read_index];
        }
    };
}

// Test
test "RingBuffer init creates an empty ring buffer" {
    const allocator = testing.allocator;
    var ring_buffer = try RingBuffer(u8).init(allocator, 256);
    defer ring_buffer.deinit();

    try testing.expect(ring_buffer.isEmpty());
    try testing.expect(ring_buffer.size == 0);
}

test "RingBuffer deinint cleans up memory" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(i32).init(allocator, 128);

    _ = buffer.push(-2);
    _ = buffer.push(512);

    buffer.deinit();
    // If there's a memory leak, the test allocator will catch it
}

test "isEmpty returns true on empty buffer" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(i16).init(allocator, 64);
    defer buffer.deinit();

    _ = buffer.push(-32);
    _ = buffer.pop();

    try testing.expect(buffer.isEmpty());
}

test "isEmpty returns fall on non empty" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(i16).init(allocator, 64);
    defer buffer.deinit();

    _ = buffer.push(-32);

    try testing.expect(!buffer.isEmpty());
}

test "isFull returns false on non full buffer" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(u16).init(allocator, 2);
    defer buffer.deinit();

    _ = buffer.push(1024);

    try testing.expect(!buffer.isFull());
}

test "isFull returns true on full buffer" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(u8).init(allocator, 1);
    defer buffer.deinit();

    _ = buffer.push(255);

    try testing.expect(buffer.isFull());
}

test "push basic functionality" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(u8).init(allocator, 2);
    defer buffer.deinit();

    _ = buffer.push(255);
    _ = buffer.push(8);

    try testing.expectEqual(buffer.size, 2);
    try testing.expectEqual(@as(u8, 255), buffer.push(16));
    try testing.expectEqual(buffer.size, 2);
}

test "push returns null if it doesn't overwrite existing data" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(i32).init(allocator, 2);
    defer buffer.deinit();

    try testing.expectEqual(null, buffer.push(1024));
}

test "pop basic funtionality" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(u16).init(allocator, 3);
    defer buffer.deinit();

    _ = buffer.push(234);

    try testing.expectEqual(1, buffer.size);
    try testing.expectEqual(@as(u16, 234), buffer.pop());
    try testing.expectEqual(0, buffer.size);
    try testing.expectEqual(null, buffer.pop());
}

test "peek returns value but doesn't decrease size" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(i8).init(allocator, 1);
    defer buffer.deinit();

    _ = buffer.push(-12);

    try testing.expectEqual(@as(i8, -12), buffer.peek());
    try testing.expectEqual(1, buffer.size);
}

test "FIFO ordering" {
    const allocator = testing.allocator;
    var buffer = try RingBuffer(u8).init(allocator, 3);
    defer buffer.deinit();

    _ = buffer.push(1);
    _ = buffer.push(2);
    _ = buffer.push(3);

    try testing.expectEqual(@as(u8, 1), buffer.pop().?);
    try testing.expectEqual(@as(u8, 2), buffer.pop().?);
    try testing.expectEqual(@as(u8, 3), buffer.pop().?);
}
