const std = @import("std");

/// Ring buffer aka Circular buffer
pub fn RingBuffer(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        buffer: []T,
        head: usize,
        tail: usize,

        pub fn init(allocator: std.mem.Allocator, buffer_capacity: usize) !Self {
            return Self{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, buffer_capacity),
                .head = 0,
                .tail = 0,
            };
        }
    };
}
