const std = @import("std");
const Stack = @import("../data_structures/stacks/stack.zig").Stack;

// Depths first searchers
pub const DepthsFirstSearch = struct {
    pub fn printPreOrderRecursive(writer: *std.Io.writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node) |n| {
            // print
            try printValue(writer, NodeType, n);
            // left
            try printPreOrderRecursive(writer, NodeType, n.left);
            // right
            try printPreOrderRecursive(writer, NodeType, n.right);
        }
    }

    pub fn printInOrderRecursive(writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node) |n| {
            // left
            try printInOrderRecursive(writer, NodeType, n.left);
            // print
            try printValue(writer, NodeType, n);
            // right
            try printInOrderRecursive(writer, NodeType, n.right);
        }
    }

    // post-order
    // works for all binary trees using comptime duck typing
    // (all binary trees should have a left and right)
    pub fn printPostOrderRecursive(writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node) |n| {
            // left
            try printPostOrderRecursive(writer, NodeType, n.left);
            // right
            try printPostOrderRecursive(writer, NodeType, n.right);
            // visit
            try printValue(writer, NodeType, n);
        }
    }

    pub fn printPostOrderIterative(allocator: std.mem.Allocator, writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node == null) return;

        var stack1 = try Stack(*NodeType).init(allocator);
        var stack2 = try Stack(*NodeType).init(allocator);
        defer stack1.deinit();
        defer stack2.deinit();

        // push the root to the first stack
        try stack1.push(node.?);

        while (stack1.getSize() > 0) {
            const current = stack1.pop() orelse unreachable;
            try stack2.push(current);

            // push left and right to stack 1
            if (current.left) |left| {
                try stack1.push(left);
            }
            if (current.right) |right| {
                try stack1.push(right);
            }
        }

        // print all nodes from stack2 (Should be post order)
        while (stack2.getSize() > 0) {
            const current = stack2.pop() orelse unreachable;
            try printValue(writer, NodeType, current);
        }
    }

    // helper functions
    fn validNode(comptime NodeType: type) void {
        // TODO: Implement proper error unions to use here
        if (!@hasField(NodeType, "value")) {
            @compileError("NodeType must have a 'value' field");
        }
        if (!@hasField(NodeType, "left")) {
            @compileError("NodeType must have a 'left' field");
        }
        if (!@hasField(NodeType, "right")) {
            @compileError("NodeType must have a 'right' field");
        }
    }

    fn printValue(writer: *std.Io.Writer, comptime NodeType: type, node: *NodeType) !void {
        try writer.print("{any}\n", .{node.value});
        try writer.flush();
    }
};
