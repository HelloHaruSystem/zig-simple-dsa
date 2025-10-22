const std = @import("std");
const list = @import("../linked_lists/doubly_linked_list.zig");

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
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
    };
}
