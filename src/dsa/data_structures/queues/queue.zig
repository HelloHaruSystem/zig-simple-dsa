const std = @import("std");
const list = @import("../linked_lists/doubly_linked_list.zig");

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        // TODO: add doc comments explainging the memory ownership model and why we leave it to the underlying data structure
        _doubly_linked_list: list.DoublyLinkedList(T),

        //TODO: init and initdefault function
        /// Initializes a queue
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                ._doubly_linked_list = list.DoublyLinkedList(T).init(allocator),
            };
        }

        /// frees the memory used by the queue
        pub fn deinit(self: *Self) void {
            self._doubly_linked_list.deinit();
        }

        pub fn enqueue(self: *Self, value: T) !void {
            try self._doubly_linked_list.append(value);
        }

        pub fn dequeue(self: *Self) ?T {
            return self._doubly_linked_list.popHead();
        }

        pub fn peek(self: *const Self) ?T {
            return self._doubly_linked_list.peekHead();
        }

        pub fn getSize(self: *const Self) usize {
            return self._doubly_linked_list.getSize();
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }
    };
}
