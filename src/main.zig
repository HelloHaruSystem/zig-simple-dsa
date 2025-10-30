const std = @import("std");
const dsa = @import("dsa");

pub fn main() !void {
    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Hello, {s}!\n", .{"DSA from Zig"});

    // Don't forget to flush
    try stdout.flush();

    // testing trees
    const Bst = dsa.trees.BinarySearchTree;
    const tree_algos = dsa.algorithms.TreeAlgos;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bst = Bst(i32).init(allocator);
    defer bst.deinit();

    try bst.insertRecursively(8);
    try bst.insertIterative(4);
    try bst.insertRecursively(16);

    // should print 4 -> 16 -> 8
    try tree_algos.DepthsFirstSearch.printPostOrderRecursive(stdout, dsa.trees.BinarySearchTree(i32).Node, bst.root);
}
