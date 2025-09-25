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
                overwritten = self.buffer[self.read_index];
                self.read_index = (self.read_index + 1) % self.buffer.len;
                self.size -= 1;
            }

            self.buffer[self.write_index] = data;
            self.write_index = (self.write_index + 1) % self.buffer.len;
            self.size += 1;

            return overwritten;
        }

        /// Follows the last in first out principle
        /// returns and removes the last added item in the ring buffer
        pub fn pop(self: *Self) ?T {
            if (self.size == 0) return null;

            const data = self.buffer[self.read_index];
            self.read_index = (self.read_index + 1) % self.buffer.len;
            self.size -= 1;

            return data;
        }

        /// Follows the last in first out principle
        /// returns the last added item in the ring buffer
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
