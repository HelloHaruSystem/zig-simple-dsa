const std = @import("std");
const LinkedList = @import("../linked_lists/singly_linked_list.zig").SinglyLinkedList;

pub fn HashMap(comptime key_type: type, comptime value_type: type) type {
    return struct {
        const Self = @This();

        // fields
        allocator: std.mem.Allocator,
        buckets: []LinkedList(Entry),
        capacity: usize,
        count: usize,

        pub fn init(allocator: std.mem.Allocator) !Self {
            const buckets = try allocator.alloc(LinkedList(Entry), 16);

            for (buckets) |*bucket| {
                bucket.* = LinkedList(Entry).init(allocator);
            }

            return Self{
                .allocator = allocator,
                .buckets = buckets,
                .capacity = 16,
                .count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.buckets) |*bucket| {
                bucket.deinit();
            }

            self.allocator.free(self.buckets);
        }

        // a entry for the bucket containing a key and value pair
        const Entry = struct {
            key: key_type,
            value: value_type,
        };
    };
}
