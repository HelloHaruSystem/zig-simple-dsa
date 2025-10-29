const std = @import("std");
const testing = std.testing;

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Internal Node struct
        pub const Node = struct {
            const This = @This();

            // node fields
            value: T,
            left: ?*Node,
            right: ?*Node,

            pub fn init(value: T) This {
                return This{
                    .value = value,
                    .left = null,
                    .right = null,
                };
            }
        };

        // BST fields
        allocator: std.mem.Allocator,
        root: ?*Node,
        size: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .root = null,
                .size = 0,
            };
        }

        // TODO: Implement:
        // make a generic post-order function to handle the traversal logic
        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub fn insertIterative(self: *Self, value: T) !void {
            if (self.root == null) {
                self.root = try self.createNode(value);
                return;
            }

            var current = self.root.*;
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

        pub fn insertRecursively(self: *Self, value: T) !void {
            self.root = try self.insertRecursivelyHelper(self.root, value);
        }

        pub fn insertRecursivelyHelper(self: *Self, node: ?*Node, value: T) !?*Node {
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

        // TODO: implement getMax(), getMin() and contains

        // Helper functions
        fn createNode(self: *Self, value: T) !*Node {
            const new_node = try self.allocator.create(Node);
            new_node.* = Node.init(value);
            return new_node;
        }
    };
}
