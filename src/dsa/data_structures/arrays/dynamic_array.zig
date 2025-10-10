const std = @import("std");
const testing = std.testing;

pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();

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

        pub fn append(self: *Self, value: T) !void {
            if (self.size >= self.buffer.len) {
                const new_array = try self.allocator.alloc(T, self.buffer.len * 2);
                @memcpy(new_array[0..self.size], self.buffer[0..self.size]);
                self.allocator.free(self.buffer);
                self.buffer = new_array;
            }

            self.buffer[self.size] = value;
            self.size += 1;
        }

        pub fn get(self: *const Self, index: usize) ?T {
            if (index >= self.size) return null;
            return self.buffer[index];
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
