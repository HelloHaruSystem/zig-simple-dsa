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

        pub fn peekHead(self: *Self) ?T {
            if (self.head) |head| {
                return head.value;
            }
            return null;
        }

        pub fn peekTail(self: *Self) ?T {
            if (self.tail) |tail| {
                return tail.value;
            }
            return null;
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

        pub fn reverse(self: *Self) void {
            if (self.isEmpty()) return;

            var current = self.head;

            while (current) |node| {
                std.mem.swap(?*Node(T), &node.next, &node.prev);

                // move to next node (prev is now the next after swap)
                current = node.prev;
            }

            // swap head and tal
            std.mem.swap(?*Node(T), &self.head, &self.tail);
        }

        pub fn sort(self: *Self) !void {
            if (self.size <= 1) return;

            const n = self.size;
            const mid_index = n / 2;

            // split list
            var left = try self.createSubList(0, mid_index);
            var right = try self.createSubList(mid_index, n);
            defer left.deinit();
            defer right.deinit();

            // divide
            try left.sort();
            try right.sort();

            // conquer
            try self.merge(&left, &right);
        }

        // helper functions
        fn createNode(self: *Self, value: T) !*Node(T) {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(value);
            return newNode;
        }

        // merge sort helper function
        fn createSubList(self: *Self, start_index: usize, end_index: usize) !Self {
            var new_list = Self.init(self.allocator);

            if (start_index >= self.size or start_index >= end_index) {
                return new_list;
            }

            var current = self.head;
            var i: usize = 0;

            // skip to start index
            while (current != null and i < start_index) : (i += 1) {
                current = current.?.next;
            }

            // copy elements over to the new list
            while (current != null and i < end_index) : (i += 1) {
                try new_list.append(current.?.value);
                current = current.?.next;
            }

            return new_list;
        }

        // merge sort helper function
        fn merge(self: *Self, left: *Self, right: *Self) !void {
            self.clear();

            var l_current = left.head;
            var r_current = right.head;

            while (l_current != null and r_current != null) {
                if (l_current.?.value <= r_current.?.value) {
                    try self.append(l_current.?.value);
                    l_current = l_current.?.next;
                } else {
                    try self.append(r_current.?.value);
                    r_current = r_current.?.next;
                }
            }

            // add remaining
            while (l_current != null) {
                try self.append(l_current.?.value);
                l_current = l_current.?.next;
            }

            while (r_current != null) {
                try self.append(r_current.?.value);
                r_current = r_current.?.next;
            }
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
