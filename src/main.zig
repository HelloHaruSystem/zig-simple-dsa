const std = @import("std");
const dsa = @import("dsa");

var stdout_buffer: [4096]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    try stdout.print("Hello, {s}!\n", .{"World"});

    // Don't forget to flush
    try stdout.flush();
}
