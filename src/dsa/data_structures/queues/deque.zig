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

        // TODO: Implement
        pub fn pushFront(self: *Self, value: T) void {
            _ = self;
            _ = value;
        }

        // TODO: Implement
        pub fn pushBack(self: *Self, value: T) void {
            _ = self;
            _ = value;
        }

        // TODO: Implement
        pub fn popFront(self: *Self) ?T {
            _ = self;
            return null;
        }

        // TODO: Implement
        pub fn popBack(self: *Self) ?T {
            _ = self;
            return null;
        }

        // TODO: Implement
        pub fn peekFront(self: *const Self) ?T {
            _ = self;
            return null;
        }

        // TODO: Implement
        pub fn peekBack(self: *const Self) ?T {
            _ = self;
            return null;
        }

        // TODO: Implement
        pub fn getSize(self: *const Self) usize {
            _ = self;
            return 0;
        }

        // TODO: Implement
        pub fn isEmpty(self: *const Self) bool {
            _ = self;
            return true;
        }
    };
}
