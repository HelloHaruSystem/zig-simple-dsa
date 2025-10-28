const std = @import("std");
const testing = std.testing;

/// A generic doubly linked list
pub fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        head: ?*Node(T),
        tail: ?*Node(T),
        size: usize,

        /// Initialize a new empty doubly linked list
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
                .tail = null,
                .size = 0,
            };
        }

        /// Clears and cleans up memory used by the list
        pub fn deinit(self: *Self) void {
            self.clear();
        }

        /// Check if the list is empty
        pub fn isEmpty(self: *Self) bool {
            return self.size == 0 and self.head == null and self.tail == null;
        }

        /// Get the size of the list
        pub fn getSize(self: *const Self) usize {
            return self.size;
        }

        /// Add a new element to the front of the list
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

        /// Add a new element to the end of the list
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

        /// Look at the first element without removing it
        /// Returns null if the list is empty
        pub fn peekHead(self: *const Self) ?T {
            if (self.head) |head| {
                return head.value;
            }
            return null;
        }

        /// Look at the last element without removing it
        /// Returns null if the list is empty
        pub fn peekTail(self: *Self) ?T {
            if (self.tail) |tail| {
                return tail.value;
            }
            return null;
        }

        /// Remove and return the first element of the list
        /// Returns null if the list is empty
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

        /// Remove and return the last element of the list
        /// Returns null if the list is empty
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

        /// Remove all elements from the list
        pub fn clear(self: *Self) void {
            if (self.isEmpty()) return;

            while (self.popHead()) |_| {
                // keep popping until empty
            }
        }

        /// Reverse the order of elements in the list
        pub fn reverse(self: *Self) void {
            if (self.isEmpty()) return;

            var current = self.head;

            while (current) |node| {
                std.mem.swap(?*Node(T), &node.next, &node.prev);

                // move to next node (prev is now the next after swap)
                current = node.prev;
            }

            // swap head and tail
            std.mem.swap(?*Node(T), &self.head, &self.tail);
        }

        /// Create an iterator for the list
        /// The iterator starts at the head of the list
        /// Use `setAtTail` to start at the tail
        /// Use `setAtHead` to set the iterator back to the head
        /// Use `next` and `prev` to traverse the list
        /// Use `reset` to reset the iterator back to the head
        pub fn iterator(self: *Self) Iterator {
            return Iterator{
                .list = self,
                .current = self.head,
            };
        }

        /// An iterator for the doubly linked list
        const Iterator = struct {
            list: *Self,
            current: ?*Node(T),

            /// Reset the iterator back to the head of the list
            pub fn reset(this: *Iterator) void {
                this.current = this.list.head;
            }

            /// Set the iterator to the head of the list
            pub fn setAtHead(this: *Iterator) void {
                this.current = this.list.head;
            }

            /// Set the iterator to the tail of the list
            pub fn setAtTail(this: *Iterator) void {
                this.current = this.list.tail;
            }

            /// Move the iterator to the next element and return its value
            /// Returns null if at the end of the list
            /// Use `prev` to go backwards
            pub fn next(this: *Iterator) ?T {
                if (this.current) |node| {
                    const value = node.value;
                    this.current = node.next;
                    return value;
                }
                return null;
            }

            /// Move the iterator to the previous element and return its value
            /// Returns null if at the start of the list
            /// Use `next` to go forwards
            pub fn prev(this: *Iterator) ?T {
                if (this.current) |current_node| {
                    if (current_node.prev) |prev_node| {
                        this.current = prev_node;
                        return prev_node.value;
                    }
                }
                return null;
            }
        };

        /// Sort the list using merge sort
        /// T must support the <= operator
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

        /// Create a new node with the given value
        /// Allocates memory for the node
        fn createNode(self: *Self, value: T) !*Node(T) {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(value);
            return newNode;
        }

        // merge sort helper functions

        /// Create a sublist from start_index (inclusive) to end_index (exclusive)
        /// If indices are out of bounds, returns an empty list
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

        /// Merge two sorted lists into the current list
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

/// A node in the doubly linked list
pub fn Node(comptime T: type) type {
    return struct {
        const Self = @This();
        value: T,
        next: ?*Self,
        prev: ?*Self,

        /// Initialize a new node with the given value
        fn init(value: T) Self {
            return Self{
                .value = value,
                .next = null,
                .prev = null,
            };
        }

        /// Set the next pointer of the node
        fn setNext(self: *Self, next: ?*Self) void {
            self.next = next;
        }

        /// Set the previous pointer of the node
        fn setPrev(self: *Self, prev: ?*Self) void {
            self.prev = prev;
        }
    };
}

// tests
test "DoublyLinkedList init creates empty list" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u8).init(allocator);
    defer list.deinit();

    try testing.expect(list.isEmpty());
    try testing.expectEqual(null, list.peekHead());
    try testing.expectEqual(null, list.peekTail());
    try testing.expectEqual(null, list.popHead());
    try testing.expectEqual(null, list.popTail());
}

test "DoublyLinkedList deinit cleans up memory" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);

    try list.prepend(-255);
    try list.prepend(255);
    try list.prepend(0);

    list.deinit();
    // If there's a memory leak, the test allocator will catch it
}

test "isEmpty returns true for a non empty list true" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i8).init(allocator);
    defer list.deinit();

    try testing.expect(list.isEmpty());
}

test "isEmpty returns false for a non empty list true" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u16).init(allocator);
    defer list.deinit();

    try list.prepend(512);

    try testing.expect(!list.isEmpty());
}

test "getSize basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u16).init(allocator);
    defer list.deinit();

    try list.prepend(32);

    try testing.expectEqual(1, list.getSize());
}

test "getSize returns 0 with empty list" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u16).init(allocator);
    defer list.deinit();

    try testing.expectEqual(0, list.getSize());
}

test "Prepend single element" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(54);

    try testing.expect(!list.isEmpty());
    try testing.expect(list.head != null);
    try testing.expectEqual(@as(i32, 54), list.head.?.value);
}

test "prepend multiple elements maintains LIFO order" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);

    try testing.expectEqual(@as(i32, 3), list.head.?.value);
    try testing.expectEqual(@as(i32, 2), list.head.?.next.?.value);
    try testing.expectEqual(@as(i32, 1), list.head.?.next.?.next.?.value);
}

test "popHead from empty list returns null" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    const result = list.popHead();
    try testing.expect(result == null);
}

test "iterator on empty list" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    var iter = list.iterator();
    try testing.expect(iter.next() == null);
}

test "iterator traverses single element" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(42);

    var iter = list.iterator();
    try testing.expectEqual(@as(i32, 42), iter.next().?);
    try testing.expect(iter.next() == null);
}

test "iterator traverses multiple elements" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);

    var iter = list.iterator();
    try testing.expectEqual(@as(i32, 3), iter.next().?);
    try testing.expectEqual(@as(i32, 2), iter.next().?);
    try testing.expectEqual(@as(i32, 1), iter.next().?);
    try testing.expect(iter.next() == null);
}

test "iterator traverses multiple elements backwards" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);

    var iter = list.iterator();
    iter.setAtTail();

    try testing.expectEqual(@as(i32, 2), iter.prev().?);
    try testing.expectEqual(@as(i32, 3), iter.prev().?);
    try testing.expect(iter.prev() == null);
}

test "iterator setAtHead functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.append(2);
    try list.append(3);

    var iter = list.iterator();
    iter.setAtTail();
    iter.setAtHead(); // This is the only method not tested elsewhere

    try testing.expectEqual(@as(i32, 1), iter.next().?);
    try testing.expectEqual(@as(i32, 2), iter.next().?);
    try testing.expectEqual(@as(i32, 3), iter.next().?);
}

test "iterator reset functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);

    var iter = list.iterator();
    try testing.expectEqual(@as(i32, 2), iter.next().?);
    try testing.expectEqual(@as(i32, 1), iter.next().?);
    try testing.expect(iter.next() == null);

    // Reset and traverse again
    iter.reset();
    try testing.expectEqual(@as(i32, 2), iter.next().?);
    try testing.expectEqual(@as(i32, 1), iter.next().?);
    try testing.expect(iter.next() == null);
}

test "memory allocation failure" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expectError(error.OutOfMemory, list.prepend(42));
}

test "with custom struct type" {
    const allocator = testing.allocator;

    const Point = struct {
        x: i32,
        y: i32,

        fn equal(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y;
        }
    };

    var list = DoublyLinkedList(Point).init(allocator);
    defer list.deinit();

    const p1 = Point{ .x = 1, .y = 2 };
    const p2 = Point{ .x = 3, .y = 4 };

    try list.prepend(p1);
    try list.prepend(p2);

    const popped = list.popHead().?;
    try testing.expect(popped.equal(p2));

    const remaining = list.popHead().?;
    try testing.expect(remaining.equal(p1));
}

test "basic reverse functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u32).init(allocator);
    defer list.deinit();

    const values = [_]u32{ 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 };

    var i: usize = 0;
    while (i < values.len) : (i += 1) {
        try list.prepend(values[i]);
    }

    list.reverse();

    for (values) |expected_value| {
        const actual = list.popHead().?;
        try testing.expectEqual(expected_value, actual);
    }

    try testing.expect(list.isEmpty());
    try testing.expect(list.head == null);
}

test "append basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.append(255);
    try list.append(0);

    try testing.expect(!list.isEmpty());
    try testing.expectEqual(@as(usize, 2), list.getSize());
    try testing.expectEqual(@as(u8, 255), list.popHead());
    try testing.expectEqual(@as(u8, 0), list.popHead());
    try testing.expect(list.isEmpty());
}

test "append vs prepend order" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.prepend(0);
    try list.append(2);

    // Should be: 0 -> 1 -> 2
    try testing.expectEqual(@as(i32, 0), list.popHead().?);
    try testing.expectEqual(@as(i32, 1), list.popHead().?);
    try testing.expectEqual(@as(i32, 2), list.popHead().?);
}

test "peekHead basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);

    try testing.expectEqual(@as(i32, 64), list.peekHead().?);
}

test "popTail basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(0);
    try list.prepend(2);

    try testing.expectEqual(@as(i32, 1), list.popTail());
    try testing.expectEqual(@as(usize, 2), list.getSize());
    try testing.expectEqual(@as(i32, 0), list.popTail());
    // try with head
    try testing.expectEqual(@as(i32, 2), list.popTail());
    try testing.expect(list.isEmpty());
}

test "peekTail basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(0);

    try testing.expectEqual(@as(i32, 1), list.peekTail());
}

test "clear basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(32);
    try list.prepend(16);

    list.clear();

    try testing.expect(list.isEmpty());
}

test "create sub list basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);
    try list.prepend(-128);
    try list.prepend(256);
    try list.prepend(-512);

    var sub_list_one = try list.createSubList(0, 2);
    var sub_list_two = try list.createSubList(2, 4);
    defer sub_list_one.deinit();
    defer sub_list_two.deinit();

    try testing.expectEqual(-512, sub_list_one.popHead());
    try testing.expectEqual(256, sub_list_one.peekHead());
    try testing.expectEqual(-128, sub_list_two.popHead());
    try testing.expectEqual(64, sub_list_two.peekTail());
}

test "merge basic functionality" {
    const allocator = testing.allocator;
    var main_list = DoublyLinkedList(i32).init(allocator);
    var left = DoublyLinkedList(i32).init(allocator);
    var right = DoublyLinkedList(i32).init(allocator);
    defer main_list.deinit();
    defer left.deinit();
    defer right.deinit();

    try left.append(1);
    try left.append(3);
    try left.append(5);

    try right.append(2);
    try right.append(4);
    try right.append(6);

    try main_list.merge(&left, &right);

    // should be merged in sorted order: 1, 2, 3, 4, 5, 6
    try testing.expectEqual(@as(i32, 1), main_list.popHead().?);
    try testing.expectEqual(@as(i32, 2), main_list.popHead().?);
    try testing.expectEqual(@as(i32, 3), main_list.popHead().?);
    try testing.expectEqual(@as(i32, 4), main_list.popHead().?);
    try testing.expectEqual(@as(i32, 5), main_list.popHead().?);
    try testing.expectEqual(@as(i32, 6), main_list.popHead().?);
    try testing.expect(main_list.isEmpty());
}

test "sort basic functionality" {
    const allocator = testing.allocator;
    var list = DoublyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(64);
    try list.append(-128);
    try list.append(256);
    try list.append(-512);

    try list.sort();

    try testing.expectEqual(@as(i32, -512), list.popHead().?);
    try testing.expectEqual(@as(i32, -128), list.popHead().?);
    try testing.expectEqual(@as(i32, 64), list.popHead().?);
    try testing.expectEqual(@as(i32, 256), list.popHead().?);
    try testing.expect(list.isEmpty());
}
