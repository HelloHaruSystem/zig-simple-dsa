const std = @import("std");
const LinkedList = @import("../linked_lists/doubly_linked_list.zig").DoublyLinkedList;
const testing = std.testing;

pub fn Deque(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        doubly_linked_list: LinkedList(T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .doubly_linked_list = LinkedList(T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.doubly_linked_list.deinit();
        }

        pub fn pushFront(self: *Self, value: T) !void {
            try self.doubly_linked_list.prepend(value);
        }

        pub fn pushBack(self: *Self, value: T) !void {
            try self.doubly_linked_list.append(value);
        }

        pub fn popFront(self: *Self) ?T {
            return self.doubly_linked_list.popHead();
        }

        pub fn popBack(self: *Self) ?T {
            return self.doubly_linked_list.popTail();
        }

        pub fn peekFront(self: *const Self) ?T {
            return self.doubly_linked_list.peekHead();
        }

        pub fn peekBack(self: *const Self) ?T {
            return self.doubly_linked_list.peekTail();
        }

        pub fn getSize(self: *const Self) usize {
            return self.doubly_linked_list.getSize();
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.getSize() == 0;
        }

        pub fn clear(self: *Self) void {
            self.doubly_linked_list.clear();
        }
    };
}
