const std = @import("std");
const dsa = @import("dsa");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [2048]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var list = dsa.lists.SinglyLinkedList(u8).init(allocator);
    defer list.deinit();

    try list.prepend(2);
    try list.prepend(4);
    try list.prepend(8);
    try list.prepend(16);
    list.reverse();

    var it = list.iterator();

    while (it.next()) |value| {
        try stdout.print("{d} -> ", .{value});
    }
    try stdout.print("null\n", .{});

    try stdout.print("Hello, {s}!\n", .{"World"});

    // Don't forget to flush
    try stdout.flush();
}

//
//const std = @import("std");
//
//pub fn HashMap(comptime K: type, comptime V: type) type {
//    return struct {
//        // ... your fields
//
//        fn hash(key: K) u64 {
//            var hasher = std.hash.Wyhash.init(0);
//            std.hash.autoHash(&hasher, key);
//            return hasher.final();
//        }
//    };
//}
//
