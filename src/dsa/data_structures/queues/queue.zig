const std = @import("std");
const ring_buffer = @import("../arrays/ring_buffer.zig");

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        ring_buffer: ring_buffer.RingBuffer(T),

        //TODO: init and initdefault function
        /// Initializes a queue with the default capacity of 16
        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .ring_buffer = try ring_buffer.RingBuffer(T).init(allocator, 16),
            };
        }

        /// frees the memory used by the queue
        pub fn deinit(self: *Self) void {
            self.ring_buffer.deinit();
        }
    };
}
