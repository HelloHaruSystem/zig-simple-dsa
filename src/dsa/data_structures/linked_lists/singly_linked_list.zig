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
        pub fn removeFirstOccurence(self: *Self, toRemove: T) bool {
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

        // TODO: mergeSort

        // TODO: toSlice

        // TODO: fromSlice

        // TODO: copy, deep copy of the list

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
// init and deinit tests
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

    try testing.expect(list.removeFirstOccurence(64));
    try testing.expectEqual(@as(usize, 1), list.getSize());
    // try remove when target is head
    try testing.expect(list.removeFirstOccurence(0));
    try testing.expect(list.isEmpty());
}

test "removeFirstOccurrence list is empty" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try testing.expect(!list.removeFirstOccurence(1000));
}

test "removeFirstOccurrence remove target not present" {
    const allocator = testing.allocator;
    var list = SinglyLinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.prepend(0);
    try list.append(2);

    try testing.expect(!list.removeFirstOccurence(1000));
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

test "concat basic funcionality" {
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
