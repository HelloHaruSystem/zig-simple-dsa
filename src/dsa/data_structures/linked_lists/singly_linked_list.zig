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

        pub fn isEmpty(self: *Self) bool {
            return self.head == null;
        }

        pub fn prepend(self: *Self, data: T) !void {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(data);

            newNode.next = self.head;
            self.head = newNode;
        }

        pub fn popHead(self: *Self) ?T {
            if (self.head == null) return null;

            const poppedHead = self.head.?;
            const data = poppedHead.data;

            self.head = poppedHead.next;
            self.allocator.destroy(poppedHead);

            return data;
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
