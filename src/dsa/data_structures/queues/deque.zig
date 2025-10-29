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
