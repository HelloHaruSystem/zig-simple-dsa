const std = @import("std");
const dynamic_array = @import("../arrays/dynamic_array.zig");

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
    };

    // TODO: push, pop, peek, getSize, isEmpty tests and docs
}
