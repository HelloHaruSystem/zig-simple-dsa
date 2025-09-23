const std = @import("std");

pub fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();
        value: T,
        next: ?*Self,
        prev: ?*Self,

        fn init(value: T) Self {
            return Self{
                .value = value,
                .next = null,
                .prev = null,
            };
        }

        fn setNext(self: *Self, next: ?*Self) void {
            self.next = next;
        }

        fn setPrev(self: *Self, prev: ?*Self) void {
            self.prev = prev;
        }
    };
}
