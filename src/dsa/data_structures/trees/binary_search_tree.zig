const std = @import("std");
const testing = std.testing;

/// Binary Search Tree data structure (unbalanced).
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
                return;
            }

            var current = self.root;
            // while current is not null
            while (current) |node| {
                // if less than current
                if (value < node.value) {
                    if (node.left == null) {
                        node.left = try self.createNode(value);
                        return;
                    } else {
                        current = node.left;
                    }
                } else {
                    // if higher than current
                    if (node.right == null) {
                        node.right = try self.createNode(value);
                        return;
                    } else {
                        current = node.right;
                    }
                }
            }

            self.size += 1;
        }

        /// Inserts a value into the Binary Search Tree
        /// Using recursion
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn insertRecursively(self: *Self, value: T) !void {
            self.root = try self.insertRecursivelyHelper(self.root, value);
            self.size += 1;
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
                return try self.createNode(value);
            }

            // unwrap
            const current_node = node.?;

            // recursive step
            if (value < current_node.value) {
                current_node.left = try self.insertRecursivelyHelper(current_node.left, value);
            } else {
                current_node.right = try self.insertRecursivelyHelper(current_node.right, value);
            }

            return node;
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
    // If there is a momory leak the testing allocator will fail this test
}
