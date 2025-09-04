const std = @import("std");
const testing = std.testing;

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        head: ?*Node(T),
        size: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .head = null,
                .size = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.popHead() != null) {
                // pop frees nodes so keep this loop body empty
            }
            // don't destroy self since the list will usually be stack allocated
        }

        pub fn isEmpty(self: *Self) bool {
            return self.size == 0 and self.head == null;
        }

        pub fn get_size(self: *Self) T {
            return self.size;
        }

        pub fn prepend(self: *Self, data: T) !void {
            const newNode = try self.allocator.create(Node(T));
            newNode.* = Node(T).init(data);

            newNode.next = self.head;
            self.head = newNode;
            self.size += 1;
        }

        // TODO: append

        pub fn popHead(self: *Self) ?T {
            if (self.head == null) return null;

            const poppedHead = self.head.?;
            const data = poppedHead.data;

            self.head = poppedHead.next;
            self.allocator.destroy(poppedHead);
            self.size -= 1;

            return data;
        }

        // TODO: remove (remove first instance of a specific value)

        pub fn contains(self: *Self, target_data: T) bool {
            var current = self.head;
            while (current) |node| {
                if (node.data == target_data) return true;
                current = node.next;
            }
            return false;
        }

        // TODO: getLast

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

        pub fn recursive_reverse(self: *Self) void {
            self.head = recursive_reverse_helper(self.head, null);
        }

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

        pub fn iterator(self: *Self) Iterator {
            return Iterator{
                .current = self.head,
                .list = self,
            };
        }

        const Iterator = struct {
            list: *Self,
            current: ?*Node(T),

            pub fn reset(this: *Iterator) void {
                this.current = this.list.head;
            }

            pub fn next(this: *Iterator) ?T {
                if (this.current) |node| {
                    const data = node.data;
                    this.current = node.next;
                    return data;
                }
                return null;
            }
        };
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

test "basic recursive functionality" {
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
