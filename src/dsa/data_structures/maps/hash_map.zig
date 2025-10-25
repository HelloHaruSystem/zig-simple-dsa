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

        // internal hash function
        // using std Wyhash
        fn hash(key: key_type) u64 {
            // using 0 as seed (mostly to make testing easier)
            // consider using std.crypto.random.int(u64) in the future
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);

            return hasher.final();
        }

        // internal function to check for equal keys
        fn keysEqual(key_a: key_type, key_b: key_type) bool {
            return std.meta.eql(key_a, key_b);
        }

        // internal function looking to see if we need to expand the capacity
        fn checkLoadFactor(self: *Self) bool {
            if (self.count == 0) return false;
            const load_factor = @as(f64, @floatFromInt(self.count)) / @as(f64, @floatFromInt(self.capacity));

            if (load_factor >= 0.75) {
                return true;
            }

            return false;
        }

        // internal function to expand the current capacity and rehash the current entries
        // into a new array 2x the size of the current
        fn expand(self: *Self) !void {
            const new_capacity: usize = self.capacity * 2;
            const new_buckets =
                try self.allocator.alloc(LinkedList(Entry), new_capacity);

            // initialize new buckets
            for (new_buckets) |*bucket| {
                bucket.* = LinkedList(Entry).init(self.allocator);
            }

            // rehash all current entries
            for (self.buckets) |*old_bucket| {
                var current = old_bucket.head;

                while (current) |node| {
                    const entry = node.data;

                    // rehash
                    const key_hash = hash(entry.key);
                    const new_index: usize = key_hash % new_capacity;

                    // insert into the new bucket
                    try new_buckets[new_index].prepend(entry);

                    // go next while current != null
                    current = node.next;
                }

                // clean up old bucket
                old_bucket.deinit();
            }

            // free old buckets array
            self.allocator.free(self.buckets);

            // update buckets and capacity
            self.buckets = new_buckets;
            self.capacity = new_capacity;
        }

        pub fn put(self: *Self, key: key_type, value: value_type) !void {
            const hashed_key = hash(key);
            const index: usize = hashed_key % self.capacity;
            var bucket = &self.buckets[index];
            var current = bucket.head;

            while (current) |node| {
                // if key is equal update existing value
                if (keysEqual(node.data.key, key)) {
                    node.data.value = value;
                    return;
                }
                current = node.next;
            }

            try bucket.prepend(Entry{
                .key = key,
                .value = value,
            });

            self.count += 1;
            const should_expand = self.checkLoadFactor();
            if (should_expand) {
                try self.expand();
            }
        }

        // TODO: get(), remove(key), contains(key) maybe an iterator to iterate over keys and values

        // a entry for the bucket containing a key and value pair
        const Entry = struct {
            key: key_type,
            value: value_type,
        };
    };
}
