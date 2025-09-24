const std = @import("std");

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

        pub fn init(allocator: std.mem.Allocator, buffer_capacity: usize) !Self {
            return Self{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, buffer_capacity),
                .write_index = 0,
                .read_index = 0,
                .size = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buffer);
        }

        pub fn isEmpty(self: *Self) bool {
            return self.size == 0;
        }

        pub fn isFull(self: *Self) bool {
            return self.size == self.buffer.len;
        }

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

        pub fn pop(self: *Self) ?T {
            if (self.size == 0) return null;

            const data = self.buffer[self.read_index];
            self.read_index = (self.read_index + 1) % self.buffer.len;
            self.size -= 1;

            return data;
        }

        pub fn peek(self: *Self) ?T {
            if (self.size == 0) return null;

            return self.buffer[self.read_index];
        }
    };
}
