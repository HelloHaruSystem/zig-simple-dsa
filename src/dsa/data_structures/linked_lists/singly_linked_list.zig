const std = @import("std");

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        head: ?*Node(T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
            };
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }
    };
}

fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        data: T,
        next: ?*Self,

        fn init(data: T) Self {
            return Self{
                .data = data,
                .next = null,
            };
        }

        fn setNext(self: *Self, next: ?*Self) void {
            self.next = next;
        }
    };
}
