const std = @import("std");
const list = @import("../linked_lists/doubly_linked_list.zig");

/// Queue data structure
pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        /// Queue is using a doubly linked list as the underlying data structure.
        /// The doubly linked list owns and is responsible for allocating the memory needed to store new items in the queue
        _doubly_linked_list: list.DoublyLinkedList(T),

        /// Initializes an empty queue
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                ._doubly_linked_list = list.DoublyLinkedList(T).init(allocator),
            };
        }

        /// Frees the memory used by the queue
        pub fn deinit(self: *Self) void {
            self._doubly_linked_list.deinit();
        }

        /// Enqueues a new value to the end of the queue
        pub fn enqueue(self: *Self, value: T) !void {
            try self._doubly_linked_list.append(value);
        }

        /// Dequeues the value in front of the queue
        /// Returns the value, or null if the queue is empty
        pub fn dequeue(self: *Self) ?T {
            return self._doubly_linked_list.popHead();
        }

        /// Returns the value in front of the queue
        /// If the queue is empty peek will return null
        pub fn peek(self: *const Self) ?T {
            return self._doubly_linked_list.peekHead();
        }

        /// Returns the size of the queue
        pub fn getSize(self: *const Self) usize {
            return self._doubly_linked_list.getSize();
        }

        /// Returns true if the queue is empty otherwise false
        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }
    };
}
