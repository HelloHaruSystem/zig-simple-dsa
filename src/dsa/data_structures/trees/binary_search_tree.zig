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
        root: *?Node,
        size: usize,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .root = null,
                .size = 0,
            };
        }
    };
}
