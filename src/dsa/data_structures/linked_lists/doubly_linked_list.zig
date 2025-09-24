const std = @import("std");

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
        pub fn getSize(self: *Self) usize {
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
        pub fn peekHead(self: *Self) ?T {
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
fn Node(comptime T: type) type {
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
