const std = @import("std");
const testing = std.testing;

/// A simple, heap-allocated dynamic array implementation that uses a tiered
/// growth strategy for resizing
pub fn DynamicArray(comptime T: type) type {
    return struct {
        const Self = @This();

        // growth strategy
        const SMALL_THRESHOLD = 4096; // 4KB - use 2x growth
        const MEDIUM_THRESHOLD = 1048576; // 1MB - use 1.5x growth

        // fields
        /// The allocator used for buffer memory
        allocator: std.mem.Allocator,
        /// the underlying memory buffer. it's length is the dynamic arrays capacity
        buffer: []T,
        /// the number of elements currently stored in the array
        size: usize,

        /// Initializes an empty dynamic array with the given initial capacity.
        /// If `capacity` is 0, a capacity 16 is used instead.
        pub fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const cap = if (capacity == 0) 16 else capacity;

            return Self{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, cap),
                .size = 0,
            };
        }

        /// initialize empty dynamic array with a default capacity of 16
        pub fn initDefault(allocator: std.mem.Allocator) !Self {
            return init(allocator, 16);
        }

        /// frees the the inner array used by the dynamic array
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.buffer);
        }

        /// returns a slice of the the values curently in the dynamic array
        pub fn items(self: *const Self) []const T {
            return self.buffer[0..self.size];
        }

        /// returns the current size of the dynamic array
        pub fn getSize(self: *const Self) usize {
            return self.size;
        }

        /// returns the current capacity of the current dynamic array
        pub fn getCapacity(self: *const Self) usize {
            return self.buffer.len;
        }

        /// appends an item to the dynamic array
        /// if needed it will expand the capacity of the inner array
        /// and copy the values to the new array
        /// will increase size by 1
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
        /// Calculates the new capacity based on the current capacity and the
        /// configured growth thresholds (SMALL_THRESHOLD and MEDIUM_THRESHOLD)
        /// - Small arrays (buffer size < 4KB): 2x growth
        /// - Medium arrays (4KB <= size < 1MB): 1.5x growth
        /// - Large arrays (size >= 1MB): 1.25x growth
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

        /// remove a value by index
        /// will decrease size by 1 if an item is removed
        /// returns true if an item is deleted
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

        /// clears all the values of the array but keeps it's current capacity
        pub fn clearRetainingCapacity(self: *Self) void {
            self.size = 0;
        }

        /// clears the values of the array and frees the memory used for it
        /// then sets the capacity to the default capacity of 16
        pub fn clearAndFree(self: *Self) !void {
            self.allocator.free(self.buffer);
            self.buffer = try self.allocator.alloc(T, 16);
            self.size = 0;
        }

        /// Gets a pointer to the value in the array by index.
        /// Returns null if index is out of bounds.
        pub fn get(self: *const Self, index: usize) ?*const T {
            if (index >= self.size) return null;
            return &self.buffer[index];
        }

        /// remove and returns the last item in the array
        /// will decrease size by 1 if an item is removed
        /// if size of the array is 0 return null
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

test "Append appends the given value at the en(self.buffer.len * 3) / 2;d of the dynamic array" {
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
