const std = @import("std");
const testing = std.testing;

/// A generic singly linked list.
pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        head: ?*Node(T),
        size: usize,

        /// Initialize an empty linked list with given allocator.
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
                .size = 0,
            };
        }

        /// Clears and cleans up all memory used by the list.
        pub fn deinit(self: *Self) void {
            self.clear();
        }

        /// Check if the list is empty.
        pub fn isEmpty(self: *Self) bool {
            return self.size == 0 and self.head == null;
        }

        /// Get the number of elements in the list.
        pub fn getSize(self: *Self) usize {
            return self.size;
        }

        /// Add an element to the front of the list.
        pub fn prepend(self: *Self, data: T) !void {
            const newNode = try self.createNode(data);

            newNode.next = self.head;
            self.head = newNode;
            self.size += 1;
        }

        /// Add an element to the end of the list.
        pub fn append(self: *Self, data: T) !void {
            const newNode = try self.createNode(data);

            if (self.isEmpty()) {
                self.head = newNode;
            } else {
                self.getTail().?.setNext(newNode);
            }

            self.size += 1;
        }

        /// Look at the first element without removing it.
        /// Returns null if the list is empty.
        pub fn peekHead(self: *Self) ?T {
            if (self.head) |head| {
                return head.data;
            }
            return null;
        }

        /// Look at the last element without removing it.
        /// Returns null if the list is empty.
        pub fn peekTail(self: *Self) ?T {
            if (self.getTail()) |tail| {
                return tail.data;
            }
            return null;
        }

        /// Remove and return the first element.
        /// Returns null if the list is empty.
        pub fn popHead(self: *Self) ?T {
            if (self.isEmpty()) return null;

            const poppedHead = self.head.?;
            const data = poppedHead.data;

            self.head = poppedHead.next;
            self.allocator.destroy(poppedHead);
            self.size -= 1;

            return data;
        }

        /// Remove and return the last element.
        /// Returns null if the list is empty
        pub fn popTail(self: *Self) ?T {
            if (self.isEmpty()) return null;

            if (self.head.?.next == null) {
                return self.popHead();
            }

            const secondToLast = self.getSecondToLast().?;
            const poppedTail = secondToLast.next.?;
            const data = poppedTail.data;

            secondToLast.next = null;
            self.allocator.destroy(poppedTail);
            self.size -= 1;

            return data;
        }

        /// Remove all elements from the list.
        pub fn clear(self: *Self) void {
            if (self.isEmpty()) return;

            while (self.popHead() != null) {
                // pop frees nodes so keep this loop body empty
            }
        }

        /// Append another list to the end of this list.
        /// The other list becomes empty after this operation.
        pub fn concat(self: *Self, other: *Self) void {
            if (other.isEmpty()) return;

            if (self.isEmpty()) {
                self.head = other.head;
                self.size = other.size;
            } else {
                self.getTail().?.next = other.head;
                self.size += other.size;
            }

            // clean other list
            other.head = null;
            other.size = 0;
        }

        /// Remove the first occurrence of the given value.
        /// Returns true if an element was removed, false otherwise.
        pub fn removeFirstOccurrence(self: *Self, toRemove: T) bool {
            if (self.isEmpty()) return false;

            // if toRemove is head
            if (self.head.?.data == toRemove) {
                return self.popHead() != null;
            }

            var current: *Node(T) = self.head.?;
            while (current.next != null) {
                if (current.next.?.data == toRemove) {
                    return self.removeAfter(current);
                }
                current = current.next.?;
            }

            return false;
        }

        /// Remove all occurrences of the given value.
        /// Returns true if at least one element was removed. false otherwise.
        pub fn removeAll(self: *Self, toRemove: T) bool {
            if (self.isEmpty()) return false;

            var hasRemoved = false;

            // keep checking and removing if needed until head is not equal toRemove
            while (self.head != null and self.head.?.data == toRemove) {
                _ = self.popHead();
                hasRemoved = true;
            }

            // check if list is empty after poping heads
            if (self.head == null) return hasRemoved;

            // go through the list and remove all instaces of toRemove
            var current = self.head.?;
            while (current.next != null) {
                if (current.next.?.data == toRemove) {
                    hasRemoved = self.removeAfter(current);
                } else {
                    current = current.next.?;
                }
            }

            return hasRemoved;
        }

        /// Check if the list contains a given value.
        pub fn contains(self: *Self, target_data: T) bool {
            var current = self.head;
            while (current) |node| {
                if (node.data == target_data) return true;
                current = node.next;
            }
            return false;
        }

        /// Get the last element's value without removing it.
        /// Returns null if the list is empty
        pub fn getLast(self: *Self) ?T {
            if (self.getTail()) |tail| {
                return tail.data;
            }

            return null;
        }

        /// Reverse the order of elements in the list
        pub fn reverse(self: *Self) void {
            var current = self.head;
            var previous: ?*Node(T) = null;

            while (current != null) {
                // get a pointer to the next node
                const next: ?*Node(T) = current.?.next;

                // reverse the current node
                current.?.next = previous;

                // advance in the list
                previous = current;
                current = next;
            }

            self.head = previous;
        }

        /// Reverse the list using recursion.
        pub fn recursive_reverse(self: *Self) void {
            self.head = recursive_reverse_helper(self.head, null);
        }

        /// Helper function for recursive reverse.
        fn recursive_reverse_helper(current: ?*Node(T), previous: ?*Node(T)) ?*Node(T) {
            if (current == null) {
                return previous;
            }

            // get the pointer to the next Node
            const next: ?*Node(T) = current.?.next;

            // reverse the current node
            current.?.next = previous;

            // advance in the list
            return recursive_reverse_helper(next, current);
        }

        /// Merge sort implementation to sort a singly linked list
        pub fn sort(self: *Self) !void {
            if (self.size <= 1) return;

            const n = self.size;
            const mid_index = n / 2;

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

        /// Create a slice from the singly linked list
        pub fn toSlice(self: *Self, allocator: std.mem.Allocator) ![]T {
            if (self.isEmpty()) return &[_]T{};

            var slice = try allocator.alloc(T, self.size);
            var current = self.head;
            var i: usize = 0;

            while (current != null) : (i += 1) {
                slice[i] = current.?.data;
                current = current.?.next;
            }

            return slice;
        }

        /// Create a new singly linked list from a slice
        pub fn fromSlice(allocator: std.mem.Allocator, slice: []const T) !Self {
            var new_list = Self.init(allocator);

            var i: usize = slice.len;

            while (i > 0) {
                i -= 1;
                try new_list.prepend(slice[i]);
            }

            return new_list;
        }

        /// Craete a copy of the singly linked list
        pub fn copy(self: *Self, allocator: std.mem.Allocator) !Self {
            var new_list = Self.init(allocator);

            var current = self.head;

            while (current != null) {
                try new_list.prepend(current.?.data);
                current = current.?.next;
            }

            new_list.reverse();
            return new_list;
        }

        /// Create an iterator for traversing the list.
        pub fn iterator(self: *Self) Iterator {
            return Iterator{
                .current = self.head,
                .list = self,
            };
        }

        /// Iterator for traversing the list elements.
        const Iterator = struct {
            list: *Self,
            current: ?*Node(T),

            /// Reset the iterator to the beginning of the list.
            pub fn reset(this: *Iterator) void {
                this.current = this.list.head;
            }

            /// Get the next element in the iteration.
            /// Returns null when there are no more elements.
            pub fn next(this: *Iterator) ?T {
                if (this.current) |node| {
                    const data = node.data;
                    this.current = node.next;
                    return data;
                }
                return null;
            }
        };

        // helper functions
        /// Get a pointer to the last node in the list.
        fn getTail(self: *Self) ?*Node(T) {
            if (self.isEmpty()) return null;

            var current = self.head;
            while (current.?.next != null) {
                current = current.?.next;
            }
            return current;
        }

        /// Get a pointer to the second-to-last node in the list.
        fn getSecondToLast(self: *Self) ?*Node(T) {
            if (self.isEmpty() or self.head.?.next == null) return null;

            var current = self.head;
            while (current.?.next.?.next != null) {
                current = current.?.next;
            }
            return current;
        }

        /// Create a new node with the given data.
        fn createNode(self: *Self, data: T) !*Node(T) {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(data);
            return newNode;
        }

        /// Remove the node that comes after the given node.
        fn removeAfter(self: *Self, current: *Node(T)) bool {
            if (current.next == null) return false;

            const nodeToRemove = current.next.?;
            current.next = nodeToRemove.next;

            self.allocator.destroy(nodeToRemove);
            self.size -= 1;

            return true;
        }

        /// Gets a pointer to the middle node of the list
        fn getMiddle(self: *Self) ?*Node(T) {
            if (self.head == null or self.size <= 1) return self.head;

            const mid_index = self.size / 2;
            var current = self.head;
            var i: usize = 0;

            while (current != null and i < mid_index) : (i += 1) {
                current = current.?.next;
            }

            return current;
        }

        /// Create a sublist from the current list using a start and end index
        /// End index is not inclusive
        /// used for merge sort implementation
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

            // copy elements from start_index to end_index
            while (current != null and i < end_index) : (i += 1) {
                try new_list.append(current.?.data);
                current = current.?.next;
            }

            return new_list;
        }

        /// Merge helper function for merge sort
        fn merge(self: *Self, left: *Self, right: *Self) !void {
            // clear current list
            self.clear();

            var l_current = left.head;
            var r_current = right.head;

            while (l_current != null and r_current != null) {
                if (l_current.?.data <= r_current.?.data) {
                    try self.append(l_current.?.data);
                    l_current = l_current.?.next;
                } else {
                    try self.append(r_current.?.data);
                    r_current = r_current.?.next;
                }
            }

            // add remaining elements
            while (l_current != null) {
                try self.append(l_current.?.data);
                l_current = l_current.?.next;
            }

            while (r_current != null) {
                try self.append(r_current.?.data);
                r_current = r_current.?.next;
            }
        }
    };
}

/// A node in the singly linked list.
fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        data: T,
        next: ?*Self,

        /// Create a new node with the given data.
        fn init(data: T) Self {
            return Self{
                .data = data,
                .next = null,
            };
        }

        // Set the next node in the chain.
        fn setNext(self: *Self, next: ?*Self) void {
            self.next = next;
        }
    };
}

// tests
test "SinglyLinkedList init creates empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try testing.expect(list.isEmpty());
    try testing.expect(list.head == null);
}

test "SinglyLinkedList deinit cleans up memory" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);

    try list.prepend(-255);
    try list.prepend(255);
    try list.prepend(0);

    list.deinit();
    // If there's a memory leak, the test allocator will catch it
}

test "isEmpty returns true for new list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try testing.expect(list.isEmpty());
}

test "isEmpty returns false for a non empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u16).init(allocator);
    defer list.deinit();

    try list.prepend(512);

    try testing.expect(!list.isEmpty());
}

test "IsEmpty returns true after popping all elements" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(4);
    try list.prepend(8);
    try list.prepend(16);

    while (list.popHead()) |_| {}

    try testing.expect(list.isEmpty());
}

test "Prepend single element" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(54);

    try testing.expect(!list.isEmpty());
    try testing.expect(list.head != null);
    try testing.expectEqual(@as(i32, 54), list.head.?.data);
}

test "prepend multiple elements maintains LIFO order" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);

    try testing.expectEqual(@as(i32, 3), list.head.?.data);
    try testing.expectEqual(@as(i32, 2), list.head.?.next.?.data);
    try testing.expectEqual(@as(i32, 1), list.head.?.next.?.next.?.data);
}

test "prepend with different types" {
    const allocator = testing.allocator;
    var string_list = SinglyLinkedList([]const u8).init(allocator);
    defer string_list.deinit();

    try string_list.prepend("World!");
    try string_list.prepend("Hello, ");

    try testing.expectEqualStrings("Hello, ", string_list.head.?.data);
    try testing.expectEqualStrings("World!", string_list.head.?.next.?.data);
}

test "popHead from empty list returns null" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    const result = list.popHead();
    try testing.expect(result == null);
}

test "contains returns false for empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expect(!list.contains(42));
}

test "contains returns true for existing element" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);

    try testing.expect(list.contains(1));
    try testing.expect(list.contains(2));
    try testing.expect(list.contains(3));
}

test "iterator on empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    var iter = list.iterator();
    try testing.expect(iter.next() == null);
}

test "iterator traverses single element" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(42);

    var iter = list.iterator();
    try testing.expectEqual(@as(i32, 42), iter.next().?);
    try testing.expect(iter.next() == null);
}

test "iterator traverses multiple elements" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
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

test "iterator reset functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
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

    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expectError(error.OutOfMemory, list.prepend(42));
}

test "with custom struct type" {
    const allocator = testing.allocator;

    const Point = struct {
        x: i32,
        y: i32,

        fn eql(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y;
        }
    };

    var list = SinglyLinkedList(Point).init(allocator);
    defer list.deinit();

    const p1 = Point{ .x = 1, .y = 2 };
    const p2 = Point{ .x = 3, .y = 4 };

    try list.prepend(p1);
    try list.prepend(p2);

    const popped = list.popHead().?;
    try testing.expect(popped.eql(p2));

    const remaining = list.popHead().?;
    try testing.expect(remaining.eql(p1));
}

test "basic reverse functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u32).init(allocator);
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

test "recursive reverse basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u32).init(allocator);
    defer list.deinit();

    const values = [_]u32{ 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 };

    var i: usize = 0;
    while (i < values.len) : (i += 1) {
        try list.prepend(values[i]);
    }

    list.recursive_reverse();

    for (values) |expected_value| {
        const actual = list.popHead().?;
        try testing.expectEqual(expected_value, actual);
    }

    try testing.expect(list.isEmpty());
    try testing.expect(list.head == null);
}

test "size increases with prepend operations" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expectEqual(@as(usize, 0), list.getSize());

    try list.prepend(10);
    try testing.expectEqual(@as(usize, 1), list.getSize());

    try list.prepend(20);
    try testing.expectEqual(@as(usize, 2), list.getSize());

    try list.prepend(30);
    try testing.expectEqual(@as(usize, 3), list.getSize());
}

test "size decreases with popHead operations" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(2);
    try list.prepend(3);
    try testing.expectEqual(@as(usize, 3), list.getSize());

    _ = list.popHead();
    try testing.expectEqual(@as(usize, 2), list.getSize());

    _ = list.popHead();
    try testing.expectEqual(@as(usize, 1), list.getSize());

    _ = list.popHead();
    try testing.expectEqual(@as(usize, 0), list.getSize());

    const result = list.popHead();
    try testing.expect(result == null);
    try testing.expectEqual(@as(usize, 0), list.getSize());
}

test "append basic funtionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
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
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.prepend(0);
    try list.append(2);

    // Should be: 0 -> 1 -> 2
    try testing.expectEqual(@as(i32, 0), list.popHead().?);
    try testing.expectEqual(@as(i32, 1), list.popHead().?);
    try testing.expectEqual(@as(i32, 2), list.popHead().?);
}

test "getLast basic funtionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.prepend(0);
    try list.append(2);

    try testing.expectEqual(@as(i32, 2), list.getLast().?);
}

test "peekHead basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);

    try testing.expectEqual(@as(i32, 64), list.peekHead().?);
}

test "removeFirstOccurrence basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);
    try list.prepend(0);

    try testing.expect(list.removeFirstOccurrence(64));
    try testing.expectEqual(@as(usize, 1), list.getSize());
    // try remove when target is head
    try testing.expect(list.removeFirstOccurrence(0));
    try testing.expect(list.isEmpty());
}

test "removeFirstOccurrence list is empty" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expect(!list.removeFirstOccurrence(1000));
}

test "removeFirstOccurrence remove target not present" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.prepend(0);
    try list.append(2);

    try testing.expect(!list.removeFirstOccurrence(1000));
}

test "popTail basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
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

test "concat basic functionality" {
    const allocator = testing.allocator;
    var list1 = SinglyLinkedList(i32).init(allocator);
    var list2 = SinglyLinkedList(i32).init(allocator);
    defer list1.deinit();
    defer list2.deinit();

    try list1.prepend(1);
    try list1.prepend(0);
    try list1.prepend(2);

    try list2.prepend(1);
    try list2.prepend(0);
    try list2.prepend(2);

    list1.concat(&list2);

    // list1 should now be: 2 -> 0 -> 1 -> 2 -> 0 -> 1
    try testing.expectEqual(@as(usize, 6), list1.getSize());
    try testing.expectEqual(@as(i32, 2), list1.popHead().?);
    try testing.expectEqual(@as(i32, 0), list1.popHead().?);
    try testing.expectEqual(@as(i32, 1), list1.popHead().?);
    try testing.expectEqual(@as(i32, 2), list1.popHead().?);
    try testing.expectEqual(@as(i32, 0), list1.popHead().?);
    try testing.expectEqual(@as(i32, 1), list1.popHead().?);
    try testing.expect(list1.isEmpty());

    // list2 should now be empty
    try testing.expect(list2.isEmpty());
    try testing.expectEqual(@as(usize, 0), list2.getSize());
    try testing.expect(list2.popHead() == null);
}

test "peekTail basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(1);
    try list.prepend(0);

    try testing.expectEqual(@as(i32, 1), list.peekTail());
}

test "peekTail on empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try testing.expectEqual(null, list.peekTail());
}

test "removeAll basic funtionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(32);
    try list.prepend(16);
    try list.prepend(8);
    try list.prepend(32);
    try list.prepend(2);

    try testing.expect(list.removeAll(32));
    try testing.expectEqual(@as(u8, 16), list.popTail());
    try testing.expect(!list.contains(32));
}

test "removeALl on empty list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try testing.expect(!list.removeAll(32));
}

test "removeALl doesn't affect non target values" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(32);
    try list.prepend(16);
    try list.prepend(8);
    try list.prepend(32);
    try list.prepend(2);

    _ = list.removeAll(32);

    try testing.expectEqual(@as(usize, 3), list.getSize());
    try testing.expect(list.contains(16));
    try testing.expect(list.contains(8));
    try testing.expect(list.contains(2));
    try testing.expect(!list.contains(32));
}

test "clear basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(32);
    try list.prepend(16);

    list.clear();

    try testing.expect(list.isEmpty());
}

test "get mid index basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);
    try list.prepend(-128);
    try list.prepend(256);
    const mid_node = list.getMiddle();

    try testing.expectEqual(-128, mid_node.?.data);
}

test "get mid index on even-sized lists" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(64);
    try list.prepend(-128);
    try list.prepend(256);
    try list.prepend(-512);
    const mid_node = list.getMiddle();

    try testing.expectEqual(-128, mid_node.?.data);
}

test "create sub list basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
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
    var main_list = SinglyLinkedList(i32).init(allocator);
    var left = SinglyLinkedList(i32).init(allocator);
    var right = SinglyLinkedList(i32).init(allocator);
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
    var list = SinglyLinkedList(i32).init(allocator);
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

test "sort single element" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(42);
    try list.sort();

    try testing.expectEqual(@as(i32, 42), list.popHead().?);
    try testing.expect(list.isEmpty());
}

test "sort already sorted list" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.append(2);
    try list.append(3);
    try list.append(4);

    try list.sort();

    try testing.expectEqual(@as(i32, 1), list.popHead().?);
    try testing.expectEqual(@as(i32, 2), list.popHead().?);
    try testing.expectEqual(@as(i32, 3), list.popHead().?);
    try testing.expectEqual(@as(i32, 4), list.popHead().?);
    try testing.expect(list.isEmpty());
}

test "toSlice basic functionality" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(0);
    try list.append(1);
    try list.append(2);
    try list.append(3);
    const slice = try list.toSlice(allocator);
    defer allocator.free(slice);

    for (slice, 0..) |number, i| {
        try testing.expectEqual(@as(i32, @intCast(i)), number);
    }
}

test "fromSlice basic functionality" {
    const allocator = testing.allocator;
    const slice = [_]i16{ 128, 256, 512, 1024 };

    var list = try SinglyLinkedList(i16).fromSlice(allocator, &slice);
    defer list.deinit();

    try testing.expectEqual(@as(usize, 4), list.size);
}

test "copy basic functionality" {
    const allocator = testing.allocator;
    var original = SinglyLinkedList(i32).init(allocator);
    defer original.deinit();

    try original.append(10);
    try original.append(20);
    try original.append(30);

    var copied = try original.copy(allocator);
    defer copied.deinit();

    try testing.expectEqual(@as(usize, 3), copied.getSize());
    try testing.expectEqual(@as(i32, 10), copied.popHead().?);
    try testing.expectEqual(@as(i32, 20), copied.popHead().?);
    try testing.expectEqual(@as(i32, 30), copied.popHead().?);
    try testing.expect(copied.isEmpty());

    // Check that original is unchanged
    try testing.expectEqual(@as(usize, 3), original.getSize());
    try testing.expectEqual(@as(i32, 10), original.peekHead().?);
}
