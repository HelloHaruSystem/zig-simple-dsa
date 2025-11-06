const std = @import("std");
const Stack = @import("../data_structures/stacks/stack.zig").Stack;
const Bst = @import("../data_structures/trees/binary_search_tree.zig").BinarySearchTree;
const testing = std.testing;

// Depth first searchers
pub const DepthsFirstSearch = struct {
    pub fn printPreOrderRecursive(writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
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

    pub fn printPreOrderIterative(allocator: std.mem.Allocator, writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node == null) return;

        var stack = try Stack(*NodeType).init(allocator);
        defer stack.deinit();

        try stack.push(node.?);

        while (stack.getSize() > 0) {
            const current = stack.pop() orelse unreachable;
            // visit
            try printValue(writer, NodeType, current);

            // right first so left is ontop of the stack
            if (current.right) |right| {
                try stack.push(right);
            }

            if (current.left) |left| {
                try stack.push(left);
            }
        }
    }

    pub fn printInOrderIterative(allocator: std.mem.Allocator, writer: *std.Io.Writer, comptime NodeType: type, node: ?*NodeType) !void {
        validNode(NodeType);

        if (node == null) return;

        var stack = try Stack(*NodeType).init(allocator);
        defer stack.deinit();

        var current = node;

        // go left
        while (current != null or stack.getSize() > 0) {

            // far left as possible
            while (current) |curr| {
                try stack.push(curr);
                current = curr.left;
            }

            // visit
            current = stack.pop();
            if (current) |curr| {
                try printValue(writer, NodeType, curr);
                // go right
                current = curr.right;
            }
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

// tests
test "printPreOrderRecursive basic functionality" {
    const allocator = testing.allocator;
    var bst = Bst(i32).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(128);
    try bst.insertIterative(32);
    try bst.insertIterative(16);
    try bst.insertRecursively(64);
    try bst.insertRecursively(2048);
    try bst.insertRecursively(1024);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);

    try DepthsFirstSearch.printPreOrderRecursive(&writer, Bst(i32).Node, bst.root);

    const output = buffer[0..writer.end];

    // Pre-order: 128, 32, 16, 64, 2048, 1024
    const expected = "128\n32\n16\n64\n2048\n1024\n";

    try testing.expectEqualStrings(expected, output);
}

test "printInOrderRecursive basic functionality" {
    const allocator = testing.allocator;
    var bst = Bst(i32).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(128);
    try bst.insertIterative(32);
    try bst.insertIterative(16);
    try bst.insertRecursively(64);
    try bst.insertRecursively(2048);
    try bst.insertRecursively(1024);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);

    try DepthsFirstSearch.printInOrderRecursive(&writer, Bst(i32).Node, bst.root);

    const output = buffer[0..writer.end];

    // In-order: 16, 32, 64, 128, 1024, 2048
    const expected = "16\n32\n64\n128\n1024\n2048\n";

    try testing.expectEqualStrings(expected, output);
}

test "printPostOrderRecursive basic functionality" {
    const allocator = testing.allocator;
    var bst = Bst(i32).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(128);
    try bst.insertIterative(32);
    try bst.insertIterative(16);
    try bst.insertRecursively(64);
    try bst.insertRecursively(2048);
    try bst.insertRecursively(1024);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);

    try DepthsFirstSearch.printPostOrderRecursive(&writer, Bst(i32).Node, bst.root);

    const output = buffer[0..writer.end];

    // Post-order: 16, 64, 32, 1024, 2048, 128
    const expected = "16\n64\n32\n1024\n2048\n128\n";

    try testing.expectEqualStrings(expected, output);
}

test "printPreOrderIterative basic functionality" {
    const allocator = testing.allocator;
    var bst = Bst(f128).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(527.25);
    try bst.insertIterative(5000.0);
    try bst.insertIterative(39.95);
    try bst.insertRecursively(5000.1);
    try bst.insertRecursively(5000.01);
    try bst.insertIterative(4999.99);
    try bst.insertRecursively(45.99);
    try bst.insertIterative(75.0);
    try bst.insertRecursively(67);
    try bst.insertIterative(12.50);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);

    try DepthsFirstSearch.printPreOrderIterative(allocator, &writer, Bst(f128).Node, bst.root);

    const output = buffer[0..writer.end];

    // Pre-order: 527.25, 39.95, 12.50, 45.99, 75.0, 67, 5000.0, 4999.99, 5000.1, 5000.01
    const expected = "527.25\n39.95\n12.5\n45.99\n75\n67\n5000\n4999.99\n5000.1\n5000.01\n";

    try testing.expectEqualStrings(expected, output);
}

test "printInOrderIterative basic functionality" {
    const allocator = testing.allocator;
    var bst = Bst(f128).init(allocator);
    defer bst.deinit();

    try bst.insertIterative(527.25);
    try bst.insertIterative(5000.0);
    try bst.insertIterative(39.95);
    try bst.insertRecursively(5000.1);
    try bst.insertRecursively(5000.01);
    try bst.insertIterative(4999.99);
    try bst.insertRecursively(45.99);
    try bst.insertIterative(75.0);
    try bst.insertRecursively(67);
    try bst.insertIterative(12.50);

    var buffer: [1024]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);

    try DepthsFirstSearch.printInOrderIterative(allocator, &writer, Bst(f128).Node, bst.root);

    const output = buffer[0..writer.end];

    // Pre-order: 12.50, 39.95, 45.99, 67, 75.0, 527.25, 4999.99, 5000.0, 5000.01, 5000.1
    const expected = "12.5\n39.95\n45.99\n67\n75\n527.25\n4999.99\n5000\n5000.01\n5000.1\n";

    try testing.expectEqualStrings(expected, output);
}
