const std = @import("std");
const testing = std.testing;

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
            while (self.popHead() != null) {
                // pop fress nodes so keep this loop body empty
            }
            // don't destroy self since the list will usually be stack allocated
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

        pub fn contains(self: *Self, target_data: T) bool {
            var current = self.head;
            while (current) |node| {
                if (node.data == target_data) return true;
                current = node.next;
            }
            return false;
        }

        // TODO: add reverse function!

        pub fn iterator(self: *Self) Iterator(self) {
            return Iterator(self){
                .current = self.head,
            };
        }

        fn Iterator(self: *Self) type {
            return struct {
                const This = @This();

                current: ?*Node(T),

                pub fn reset(this: *This) void {
                    this.current = self.head;
                }

                pub fn next(this: *This) ?T {
                    if (this.current) |node| {
                        const data = node.data;
                        this.current = node.next;
                        return data;
                    }
                    return null;
                }
            };
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
