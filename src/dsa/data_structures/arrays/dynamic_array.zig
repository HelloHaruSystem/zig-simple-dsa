const std = @import("std");
const testing = std.testing;

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();

        const SMALL_THRESHOLD = 4096; // 4KB - use 2x growth
        const MEDIUM_THRESHOLD = 1048576; // 1MB - use 1.5x growth

        // Fields
        allocator: std.mem.Allocator,
        buffer: []T,
        size: usize,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const cap = if (capacity == 0) 1 else capacity;

            return Self{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, cap),
                .size = 0,
            };
        }

        pub fn initDefault(allocator: std.mem.Allocator) !Self {
            return init(allocator, 16);
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buffer);
        }

        pub fn items(self: *const Self) []const T {
            return self.buffer[0..self.size];
        }

        pub fn getSize(self: *const Self) usize {
            return self.size;
        }

        pub fn getCapacity(self: *const Self) usize {
            return self.buffer.len;
        }

        pub fn append(self: *Self, value: T) !void {
            if (self.size >= self.buffer.len) {
                const new_capacity = self.calculateNewCapacity();
                const new_array = try self.allocator.alloc(T, new_capacity);
                @memcpy(new_array[0..self.size], self.buffer[0..self.size]);
                self.allocator.free(self.buffer);
                self.buffer = new_array;
            }

            self.buffer[self.size] = value;
            self.size += 1;
        }

        // helper function for append
        fn calculateNewCapacity(self: *const Self) usize {
            const current_bytes = self.buffer.len * @sizeOf(T);

            if (current_bytes < SMALL_THRESHOLD) {
                // Small arrays: double (2x)
                return self.buffer.len * 2;
            } else if (current_bytes < MEDIUM_THRESHOLD) {
                // Medium arrays: 1.5x growth
                return (self.buffer.len * 3) / 2;
            } else {
                // Large arrays: 1.25x growth
                return (self.buffer.len * 5) / 4;
            }
        }

        pub fn remove(self: *Self, index_to_remove: usize) bool {
            if (index_to_remove >= self.size) return false;

            if (index_to_remove < self.size - 1) {
                const dst = self.buffer[index_to_remove .. self.size - 1];
                const src = self.buffer[index_to_remove + 1 .. self.size];
                std.mem.copyForwards(T, dst, src);
            }

            self.size -= 1;
            return true;
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.size = 0;
        }

        pub fn clearAndFree(self: *Self) void {
            self.allocator.free(self.buffer);
            try self.allocator.alloc(T, 1);
            self.size = 0;
        }

        pub fn get(self: *const Self, index: usize) ?T {
            if (index >= self.size) return null;
            return self.buffer[index];
        }

        pub fn pop(self: *Self) ?T {
            if (self.size == 0) return null;

            self.size -= 1;
            return self.buffer[self.size];
        }
    };
}

// tests
test "Dynamic array init creates an empty array with the length of the given capacity" {
    const allocator = testing.allocator;
    var new_dynamic_array = try DynamicArray(i32).init(allocator, 10);
    defer new_dynamic_array.deinit();

    try testing.expect(new_dynamic_array.size == 0);
    try testing.expect(new_dynamic_array.buffer.len == 10);
}

test "Append appends the given value at the end of the dynamic array" {
    const allocator = testing.allocator;
    var new_dynamic_array = try DynamicArray(u8).initDefault(allocator);
    defer new_dynamic_array.deinit();

    try new_dynamic_array.append(32);
    try new_dynamic_array.append(64);

    try testing.expectEqual(new_dynamic_array.buffer[0], 32);
    try testing.expectEqual(new_dynamic_array.buffer[1], 64);
}

test "Append when the capacity is at it's limit will increase the capacity of the inner array" {
    const allocator = testing.allocator;
    var new_dynamic_array = try DynamicArray(i32).init(allocator, 2);
    defer new_dynamic_array.deinit();

    try new_dynamic_array.append(128);
    try new_dynamic_array.append(256);
    try new_dynamic_array.append(512);

    try testing.expectEqual(4, new_dynamic_array.buffer.len);
    try testing.expectEqual(3, new_dynamic_array.size);
}
