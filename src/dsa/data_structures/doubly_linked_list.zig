const std = @import("std");

pub fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        head: ?*Node(T),
        tail: ?*Node(T),
        size: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
                .tail = null,
                .size = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.clear();
        }

        pub fn isEmpty(self: *Self) bool {
            return self.size == 0 and self.head == null and self.tail == null;
        }

        pub fn getSize(self: *Self) usize {
            return self.size;
        }

        pub fn prepend(self: *Self, value: T) !void {
            const newNode = try self.createNode(value);

            newNode.setNext(self.head);
            newNode.setPrev(null);

            if (self.head) |oldHead| {
                oldHead.setPrev(newNode);
            } else {
                self.tail = newNode;
            }

            self.head = newNode;
            self.size += 1;
        }

        pub fn append(self: *Self, value: T) !void {
            const newNode = try self.createNode(value);

            newNode.setNext(null);
            newNode.setPrev(self.tail);

            if (self.tail) |oldTail| {
                oldTail.setNext(newNode);
            } else {
                self.head = newNode;
            }

            self.tail = newNode;
            self.size += 1;
        }

        pub fn popHead(self: *Self) ?T {
            if (self.isEmpty()) return null;

            const poppedHead = self.head.?;
            const value = poppedHead.value;

            if (poppedHead.next) |newHead| {
                newHead.setPrev(null);
                self.head = newHead;
            } else {
                self.head = null;
                self.tail = null;
            }

            self.size -= 1;
            self.allocator.destroy(poppedHead);

            return value;
        }

        pub fn popTail(self: *Self) ?T {
            if (self.isEmpty()) return null;

            const poppedTail = self.tail.?;
            const value = poppedTail.value;

            if (poppedTail.prev) |newTail| {
                newTail.setNext(null);
                self.tail = newTail;
            } else {
                self.head = null;
                self.tail = null;
            }

            self.allocator.destroy(poppedTail);
            self.size -= 1;

            return value;
        }

        pub fn clear(self: *Self) void {
            if (self.isEmpty()) return;

            while (self.popHead()) |_| {
                // keep popping until empty
            }
        }

        // helper functions
        fn createNode(self: *Self, value: T) !*Node(T) {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(value);
            return newNode;
        }
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
