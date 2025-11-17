const std = @import("std");
const tree_algos = @import("../../algorithms/tree_algorithms.zig").DepthFirstSearch;
const testing = std.testing;

/// Binary Search Tree data structure
/// This is a strict (no duplicates) and unbalanced Binary Search Tree
pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Internal Node struct
        pub const Node = struct {
            const This = @This();

            // node fields
            /// The value that the node holds
            value: T,
            /// The Nodes left child (can be null)
            left: ?*Node,
            /// The nodes right child (can be null)
            right: ?*Node,

            /// Initializes a new node with the given value
            pub fn init(value: T) This {
                return This{
                    .value = value,
                    .left = null,
                    .right = null,
                };
            }
        };

        // BST fields
        /// The allocator used to allocate the memory needed by the Binary Search Tree
        allocator: std.mem.Allocator,
        /// The root node of the Binary Search Tree
        /// This is null when just initialized or empty
        root: ?*Node,
        /// This size of the Binary Search Tree
        /// This field is equal to the number of values inserted into the tree
        size: usize,

        /// Initializes an empty Binary Search Tree
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .root = null,
                .size = 0,
            };
        }

        /// Frees the memory used by the Binary Search Tree
        pub fn deinit(self: *Self) void {
            self.freeSubTree(self.root);
        }

        /// Inserts a value into the Binary Search Tree
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn insertIterative(self: *Self, value: T) !void {
            if (self.root == null) {
                self.root = try self.createNode(value);
                self.size += 1;
                return;
            }

            var current = self.root;
            // while current is not null
            while (current) |node| {
                // if less than current
                if (value < node.value) {
                    if (node.left == null) {
                        node.left = try self.createNode(value);
                        self.size += 1;
                        return;
                    } else {
                        current = node.left;
                    }
                } else if (value > node.value) {
                    // if higher than current
                    if (node.right == null) {
                        node.right = try self.createNode(value);
                        self.size += 1;
                        return;
                    } else {
                        current = node.right;
                    }
                } else {
                    // no duplicate
                    return;
                }
            }
        }

        /// Inserts a value into the Binary Search Tree
        /// Using recursion
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn insertRecursively(self: *Self, value: T) !void {
            if (self.isEmpty()) {
                self.root = try self.createNode(value);
                self.size += 1;
                return;
            }

            self.root = try self.insertRecursivelyHelper(self.root, value);
        }

        /// Deletes a value from the binary search tree
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn deleteIterative(self: *Self, value: T) void {
            if (self.root == null) return;

            var parent: ?*Node = null;
            // Safe to unwrap node because of the null check at the start
            var current = self.root;
            var is_left_child = false;

            // search step
            while (current) |current_node| {
                if (value < current_node.value) {
                    // go left
                    parent = current_node;
                    current = current_node.left;
                    is_left_child = true;
                } else if (value > current_node.value) {
                    // go right
                    parent = current_node;
                    current = current_node.right;
                    is_left_child = false;
                } else {
                    // node found

                    // only right child
                    if (current_node.left == null) {
                        const replacement = current_node.right;

                        if (parent == null) {
                            // delete root
                            self.root = replacement;
                        } else if (is_left_child) {
                            parent.?.left = replacement;
                        } else {
                            parent.?.right = replacement;
                        }

                        self.allocator.destroy(current_node);
                        self.size -= 1;
                        return;
                    }

                    // only left child
                    if (current_node.right == null) {
                        const replacement = current_node.left;

                        if (parent == null) {
                            // delete root
                            self.root = replacement;
                        } else if (is_left_child) {
                            parent.?.left = replacement;
                        } else {
                            parent.?.right = replacement;
                        }

                        self.allocator.destroy(current_node);
                        self.size -= 1;
                        return;
                    }

                    // two children
                    var successor_parent: *Node = current_node;
                    var successor = current_node.right.?;

                    while (successor.left) |left_node| {
                        successor_parent = successor;
                        successor = left_node;
                    }

                    // copy successor value to current node
                    current_node.value = successor.value;

                    // delete the successor node
                    if (successor_parent == current_node) {
                        // successor is the direct right child
                        successor_parent.right = successor.right;
                    } else {
                        successor_parent.left = successor.right;
                    }

                    self.allocator.destroy(successor);
                    self.size -= 1;
                }
            }
        }

        /// Deletes a value from the binary search tree
        /// Using recursion
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn deleteRecursive(self: *Self, value: T) void {
            self.root = self.deleteRecursiveHelper(self.root, value);
        }

        /// Returns the current size of the Binary Search Tree
        /// The size represents the number of entries
        pub fn getSize(self: *const Self) usize {
            return self.size;
        }

        /// Returns true if the Binary Search tree is empty
        pub fn isEmpty(self: *const Self) bool {
            return self.size == 0;
        }

        /// Returns the highest value in the Binary Search Tree
        /// If the tree is empty return null
        /// time complexity O(h) where h is the height of the tree
        pub fn getMax(self: *const Self) ?T {
            if (self.isEmpty()) return null;

            // Since we checked already if the bst is empty we can unwrap the root
            var current = self.root.?;

            // Only visit right pointers since we are looking for the highest value in the binary search tree
            while (current.right) |right_node| {
                current = right_node;
            }

            return current.value;
        }

        /// Returns the lowest value in the Binary Search Tree
        /// If the tree is empty return null
        /// Time complexity O(h) where h is the height of the tree
        pub fn getMin(self: *const Self) ?T {
            if (self.isEmpty()) return null;

            // since we checked already if the bst is empty we can unwrap the root
            var current = self.root.?;

            // Only visit left pointers since we are looking for the lowest value in the binary search tree
            while (current.left) |left_node| {
                current = left_node;
            }

            return current.value;
        }

        /// Returns true if Binary Search Tree contains the given value otherwise false
        /// Time complexity O(h) where h is the height of the tree
        pub fn contains(self: *const Self, value: T) bool {
            if (self.isEmpty()) return false;

            var current = self.root;

            while (current) |node| {
                const current_value = node.value;

                if (current_value == value) {
                    return true;
                }

                if (value < current_value) {
                    current = node.left;
                } else {
                    current = node.right;
                }
            }

            return false;
        }

        // Helper functions
        /// Internal Recursive helper function for inserts
        fn insertRecursivelyHelper(self: *Self, node: ?*Node, value: T) !?*Node {
            // base case
            if (node == null) {
                const new_node = try self.createNode(value);
                self.size += 1;
                return new_node;
            }

            // unwrap
            const current_node = node.?;

            // recursive step
            if (value < current_node.value) {
                current_node.left = try self.insertRecursivelyHelper(current_node.left, value);
            } else if (value > current_node.value) {
                current_node.right = try self.insertRecursivelyHelper(current_node.right, value);
            } else {
                return current_node;
            }

            return node;
        }

        /// Internal recursive helper function for deletions in the binary search tree
        fn deleteRecursiveHelper(self: *Self, node: ?*Node, value: T) ?*Node {
            // base case
            if (node == null) return null;

            // Safe to unwrap node because of the null check above
            const current_node = node.?;

            // search step
            if (value < current_node.value) {
                // go left
                current_node.left = self.deleteRecursiveHelper(current_node.left, value);
            } else if (value > current_node.value) {
                current_node.right = self.deleteRecursiveHelper(current_node.right, value);
            } else {
                // Node found

                // only right child
                if (current_node.left == null) {
                    const replacement = current_node.right;
                    self.allocator.destroy(current_node);
                    self.size -= 1;
                    return replacement;
                }

                // only left child
                if (current_node.right == null) {
                    const replacement = current_node.left;
                    self.allocator.destroy(current_node);
                    self.size -= 1;
                    return replacement;
                }

                // two children
                const successsor_value = self.getMinFromNode(current_node.right);

                // copy the successors value to the current node
                if (successsor_value) |s_value| {
                    current_node.value = s_value;

                    // Recursivly delete the successor node from the subtree (doesn't have two children)
                    current_node.right = self.deleteRecursiveHelper(current_node.right, s_value);
                } else {
                    // should be unreachable
                    unreachable;
                }
            }

            // This returns the current node's pointer up the stack
            // when no deletion happened at this level (search step)
            // or when the node was a two-child deletion (Case 3)
            return node;
        }

        /// Helper function to find minimum value in a subtree starting from the given node
        fn getMinFromNode(self: *const Self, start_node: ?*Node) ?T {
            _ = self;
            if (start_node == null) return null;

            var current = start_node.?;

            while (current.left) |left_node| {
                current = left_node;
            }

            return current.value;
        }

        /// Internal method used by the BInary Search Tree to create a new node
        /// This is used when inserting into the tree
        fn createNode(self: *Self, value: T) !*Node {
            const new_node = try self.allocator.create(Node);
            new_node.* = Node.init(value);
            return new_node;
        }

        /// Internal method for freeing memory used by the Binary Search Tree
        /// This is used by the deinit method
        /// THis is a recursive method that uses Post-order for traversal
        fn freeSubTree(self: *Self, node: ?*Node) void {
            if (node) |n| {
                self.freeSubTree(n.left);
                self.freeSubTree(n.right);
                self.allocator.destroy(n);
            }
        }
    };
}

// tests
test "Binary Search Tree init method initializes a new empty binary search tree" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(i32).init(allocator);
    defer bst.deinit();

    try testing.expect(bst.isEmpty());
    try testing.expect(bst.getSize() == 0);
}

test "Binary Seatch Tree deinit cleans up memory properly" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(f128).init(allocator);

    try bst.insertIterative(34567.9876);
    try bst.insertRecursively(9876.345);

    bst.deinit();
    // If there is a memory leak the testing allocator will fail this test
}

test "insertIterative basic functionality" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(u8).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(8);
    try bst.insertIterative(64);
    try bst.insertIterative(128);
    try bst.insertIterative(32);
    try bst.insertIterative(4);

    var buffer: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try tree_algos.printPreOrderRecursive(&writer, BinarySearchTree(u8).Node, bst.root);
    const output = buffer[0..writer.end];
    // pre order 8, 4, 64, 32, 128
    const expected = "8\n4\n64\n32\n128\n";

    try testing.expectEqualStrings(expected, output);
    try testing.expect(bst.getSize() == 5);
    try testing.expect(!bst.isEmpty());
    try testing.expect(bst.contains(32));
}

test "insertIterative rejects duplicates" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(u8).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(10);
    try testing.expect(bst.getSize() == 1);

    try bst.insertIterative(10);

    try testing.expect(bst.getSize() == 1);
}

test "insertRecursive basic functionality" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(i64).init(allocator);
    defer bst.deinit();

    for (1..6) |i| {
        try bst.insertRecursively(@as(i64, @intCast(i)));
    }

    var buffer: [512]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try tree_algos.printPreOrderRecursive(&writer, BinarySearchTree(i64).Node, bst.root);
    const output = buffer[0..writer.end];
    // pre order 1, 2, 3, 4, 5
    const expected = "1\n2\n3\n4\n5\n";

    try testing.expectEqualStrings(expected, output);
    try testing.expect(bst.getSize() == 5);
    try testing.expect(!bst.isEmpty());

    for (0..bst.getSize()) |i| {
        try testing.expect(bst.contains(@as(i64, @intCast(i + 1))));
    }
}

test "insertRecursive rejects duplicates" {
    const allocator = testing.allocator;
    var bst = BinarySearchTree(u8).init(allocator);
    defer bst.deinit();

    try bst.insertRecursively(10);
    try testing.expect(bst.getSize() == 1);

    try bst.insertRecursively(10);

    try testing.expect(bst.getSize() == 1);
}
