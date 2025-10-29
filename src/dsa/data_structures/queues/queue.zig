const std = @import("std");
const list = @import("../linked_lists/doubly_linked_list.zig");
const testing = std.testing;

/// Queue data structure
pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        /// Queue is using a doubly linked list as the underlying data structure.
        /// The doubly linked list owns and is responsible for allocating the memory needed to store new items in the queue
        doubly_linked_list: list.DoublyLinkedList(T),

        /// Initializes an empty queue
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .doubly_linked_list = list.DoublyLinkedList(T).init(allocator),
            };
        }

        /// Frees the memory used by the queue
        pub fn deinit(self: *Self) void {
            self.doubly_linked_list.deinit();
        }

        /// Enqueues a new value to the end of the queue
        pub fn enqueue(self: *Self, value: T) !void {
            try self.doubly_linked_list.append(value);
        }

        /// Dequeues the value in front of the queue
        /// Returns the value, or null if the queue is empty
        pub fn dequeue(self: *Self) ?T {
            return self.doubly_linked_list.popHead();
        }

        /// Returns the value in front of the queue
        /// If the queue is empty peek will return null
        pub fn peek(self: *const Self) ?T {
            return self.doubly_linked_list.peekHead();
        }

        /// Returns the size of the queue
        pub fn getSize(self: *const Self) usize {
            return self.doubly_linked_list.getSize();
        }

        /// Returns true if the queue is empty otherwise false
        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }
    };
}

// tests
test "queue init function returns an empty queue" {
    const allocator = testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    try testing.expect(queue.isEmpty());
}

test "queue deinit cleans up memory properly" {
    const allocator = testing.allocator;
    var queue = Queue(u8).init(allocator);

    try queue.enqueue(16);
    try queue.enqueue(32);

    queue.deinit();
    // If there is a memory leak the testing allocator will fail this test
}

test "enqueue basic functionality" {
    const allocator = testing.allocator;
    var queue = Queue(f32).init(allocator);
    defer queue.deinit();

    try queue.enqueue(45.231);
    try queue.enqueue(-34.12);

    try testing.expect(queue.getSize() == 2);
    try testing.expect(!queue.isEmpty());
    try testing.expectEqual(@as(f32, 45.231), queue.peek().?);
    try testing.expectEqual(@as(f32, 45.231), queue.dequeue().?);
}

test "dequeue basic functionality" {
    const allocator = testing.allocator;
    var queue = Queue(i8).init(allocator);
    defer queue.deinit();

    try queue.enqueue(8);
    try queue.enqueue(16);
    try queue.enqueue(32);

    try testing.expectEqual(@as(i8, 8), queue.dequeue().?);
    try testing.expect(queue.getSize() == 2);
    try testing.expectEqual(@as(i8, 16), queue.dequeue().?);
    try testing.expect(queue.getSize() == 1);
    try testing.expectEqual(@as(i8, 32), queue.dequeue().?);
    try testing.expect(queue.getSize() == 0);
}

test "dequeue returns null on empty queue" {
    const allocator = testing.allocator;
    var queue = Queue(u16).init(allocator);
    defer queue.deinit();

    try testing.expectEqual(null, queue.dequeue());
}

test "peek returns the value in front of the queue without removing it" {
    const allocator = testing.allocator;
    var queue = Queue(f64).init(allocator);
    defer queue.deinit();

    try queue.enqueue(34200.232);
    try queue.enqueue(63420.54345);

    try testing.expectEqual(@as(f64, 34200.232), queue.peek().?);
    try testing.expect(queue.getSize() == 2);
}

test "peek returns null on empty queue" {
    const allocator = testing.allocator;
    var queue = Queue(i64).init(allocator);
    defer queue.deinit();

    try testing.expectEqual(null, queue.peek());
}

test "getSize returns the correct size as a usize" {
    const allocator = testing.allocator;
    var queue = Queue(u8).init(allocator);
    defer queue.deinit();

    try queue.enqueue(127);
    try queue.enqueue(1);
    try queue.enqueue(72);
    _ = queue.dequeue();
    _ = queue.dequeue();

    try testing.expect(queue.getSize() == 1);
}

test "isEmpty basic functionality" {
    const allocator = testing.allocator;
    var queue = Queue(i16).init(allocator);
    defer queue.deinit();

    try queue.enqueue(-128);

    try testing.expect(!queue.isEmpty());
    try testing.expectEqual(@as(i16, -128), queue.dequeue().?);
    try testing.expect(queue.isEmpty());
}
