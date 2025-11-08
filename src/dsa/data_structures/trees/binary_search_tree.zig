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
        }

        /// Inserts a value into the Binary Search Tree
        /// Using recursion
        /// Time complexity worst case O(n)
        /// Time complexity average case O(log n)
        pub fn insertRecursively(self: *Self, value: T) !void {
            self.root = try self.insertRecursivelyHelper(self.root, value);
        }

        // TODO: implement getMax(), getMin() and contains

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
