const std = @import("std");
const LinkedList = @import("../linked_lists/doubly_linked_list.zig").DoublyLinkedList;
const testing = std.testing;

/// Deque (aka double ended queue) data structure
pub fn Deque(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        /// Deque is using a doubly linked list as the underlying data structure.
        /// The doubly linked list owns and is responsible for allocating the memory needed to store new items in the queue
        doubly_linked_list: LinkedList(T),

        /// Initializes an empty deque
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .doubly_linked_list = LinkedList(T).init(allocator),
            };
        }

        /// Frees the memory used by the deque
        pub fn deinit(self: *Self) void {
            self.doubly_linked_list.deinit();
        }

        /// Pushes a value to the front of the deque
        pub fn pushFront(self: *Self, value: T) !void {
            try self.doubly_linked_list.prepend(value);
        }

        /// Pushes a value to the back of the deque
        pub fn pushBack(self: *Self, value: T) !void {
            try self.doubly_linked_list.append(value);
        }

        /// Pops the front value of the deque
        /// If the deque is empty this function will return null
        pub fn popFront(self: *Self) ?T {
            return self.doubly_linked_list.popHead();
        }

        /// Pops the back value of the deque
        /// If the deque is empty this function will return null
        pub fn popBack(self: *Self) ?T {
            return self.doubly_linked_list.popTail();
        }

        /// Returns the value in front of the deque without removing it
        /// If the deque is empty this function will return null
        pub fn peekFront(self: *const Self) ?T {
            return self.doubly_linked_list.peekHead();
        }

        /// Returns the value in the back of the deque without removing it
        /// If the deque is empty this function will return null
        pub fn peekBack(self: *const Self) ?T {
            return self.doubly_linked_list.peekTail();
        }

        /// Returns the size of the deque
        /// The size will be equal to the amount of values it holds
        pub fn getSize(self: *const Self) usize {
            return self.doubly_linked_list.getSize();
        }

        /// Returns true if the deque is empty, otherwise false
        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }

        /// Clears the deque and removes all items it holds
        /// This will also free the memory used for the items removed
        pub fn clear(self: *Self) void {
            self.doubly_linked_list.clear();
        }
    };
}

// tests
test "Deque init method returns an empty deque" {
    const allocator = testing.allocator;
    var deque = Deque(u8).init(allocator);
    defer deque.deinit();

    try testing.expect(deque.isEmpty());
    try testing.expect(deque.getSize() == 0);
}

test "Deque deinit method frees the memory used by the deque" {
    const allocator = testing.allocator;
    var deque = Deque(f64).init(allocator);

    try deque.pushFront(9765.45678);
    try deque.pushBack(123456.6543);

    deque.deinit();
    // the testing allocator will fail this test in case of a memory leak
}

test "pushFront method basic funtionality" {
    const allocator = testing.allocator;
    var deque = Deque(i32).init(allocator);
    defer deque.deinit();

    try deque.pushFront(2);
    try deque.pushFront(1);
    try deque.pushFront(0);

    try testing.expect(deque.getSize() == 3);
    try testing.expect(!deque.isEmpty());
    for (0..3) |i| {
        try testing.expectEqual(@as(i32, @intCast(i)), deque.popFront().?);
    }
}

test "pushBack method basic functionality" {
    const allocator = testing.allocator;
    var deque = Deque(u8).init(allocator);
    defer deque.deinit();

    try deque.pushBack('c');
    try deque.pushBack('a');
    try deque.pushBack('b');

    try testing.expectEqual(@as(u8, 'c'), deque.popFront().?);
    try testing.expectEqual(@as(u8, 'b'), deque.popBack().?);
    try testing.expectEqual(@as(u8, 'a'), deque.peekFront().?);
}

test "popFront method basic functionality" {
    const allocator = testing.allocator;
    var deque = Deque(u16).init(allocator);
    defer deque.deinit();

    try deque.pushBack(7);
    try deque.pushFront(6);
    try deque.pushBack(8);
    try deque.pushFront(5);

    try testing.expectEqual(@as(u16, 5), deque.popFront().?);
    try testing.expectEqual(@as(u16, 6), deque.popFront().?);
    try testing.expectEqual(@as(u16, 7), deque.popFront().?);
    try testing.expectEqual(@as(u16, 8), deque.popFront().?);
}

test "popFront returns null on empty deque" {
    const allocator = testing.allocator;
    var deque = Deque(u32).init(allocator);
    defer deque.deinit();

    try testing.expectEqual(null, deque.popFront());
}

test "popBack method basic functionality" {
    const allocator = testing.allocator;
    var deque = Deque(i16).init(allocator);
    defer deque.deinit();

    try deque.pushBack(7);
    try deque.pushFront(6);
    try deque.pushBack(8);
    try deque.pushFront(5);

    try testing.expectEqual(@as(i16, 8), deque.popBack().?);
    try testing.expectEqual(@as(i16, 7), deque.popBack().?);
    try testing.expectEqual(@as(i16, 6), deque.popBack().?);
    try testing.expectEqual(@as(i16, 5), deque.popBack().?);
}

test "popBack returns null on empty deque" {
    const allocator = testing.allocator;
    var deque = Deque(i64).init(allocator);
    defer deque.deinit();

    try testing.expectEqual(null, deque.popBack());
}

test "peekFront method basic funtionality" {
    const allocator = testing.allocator;
    var deque = Deque(f128).init(allocator);
    defer deque.deinit();

    try deque.pushFront(12357546.12);
    try deque.pushFront(123547.123357);

    try testing.expect(!deque.isEmpty());
    try testing.expectEqual(@as(f128, 123547.123357), deque.peekFront().?);
    try testing.expect(deque.getSize() == 2);
    try testing.expectEqual(@as(f128, 123547.123357), deque.popFront().?);
}

test "peekFront returns null on empty deque" {
    const allocator = testing.allocator;
    var deque = Deque(f128).init(allocator);
    defer deque.deinit();

    try testing.expectEqual(null, deque.peekFront());
}

test "peekBack method basic funtionality" {
    const allocator = testing.allocator;
    var deque = Deque([]const u8).init(allocator);
    defer deque.deinit();

    try deque.pushFront("This string is in front");
    try deque.pushBack("This string is in the back");

    try testing.expect(!deque.isEmpty());
    try testing.expectEqual(@as([]const u8, "This string is in the back"), deque.peekBack().?);
    try testing.expect(deque.getSize() == 2);
    try testing.expectEqual(@as([]const u8, "This string is in the back"), deque.popBack().?);
}

test "peekBack returns null on empty deque" {
    const allocator = testing.allocator;
    var deque = Deque(i128).init(allocator);
    defer deque.deinit();

    try testing.expectEqual(null, deque.peekBack());
}

test "getSize basic funtionality" {
    const allocator = testing.allocator;
    var deque = Deque(u8).init(allocator);
    defer deque.deinit();

    for (0..10) |i| {
        try deque.pushFront(@as(u8, @intCast(i)));
    }
    var counter: usize = 10;

    while (counter > 0) : (counter -= 1) {
        try testing.expectEqual(counter, deque.getSize());
        _ = deque.popBack();
    }
    try testing.expect(deque.getSize() == 0);
}

test "isEmpty basic functionality" {
    const allocator = testing.allocator;
    var deque = Deque(i8).init(allocator);
    defer deque.deinit();

    try deque.pushBack(-7);

    try testing.expect(!deque.isEmpty());
    try testing.expectEqual(@as(i8, -7), deque.popBack().?);
    try testing.expect(deque.isEmpty());
}

test "clear method basic functionality" {
    const allocator = testing.allocator;
    var deque = Deque(i8).init(allocator);
    defer deque.deinit();

    for (0..4) |i| {
        try deque.pushBack(@as(i8, @intCast(i)));
    }
    deque.clear();

    try testing.expectEqual(null, deque.popFront());
    try testing.expectEqual(null, deque.popBack());
    try testing.expectEqual(null, deque.peekFront());
    try testing.expectEqual(null, deque.peekBack());
    try testing.expect(deque.getSize() == 0);
    try testing.expect(deque.isEmpty());
}

test "clear method cleans up memory used by the deque" {
    const allocator = testing.allocator;
    var deque = Deque(u8).init(allocator);
    defer deque.deinit();

    for (0..20) |i| {
        try deque.pushBack(@as(u8, @intCast(i)));
    }

    deque.clear();
    // the testing allocator will fail this test if it leaks memory
}
