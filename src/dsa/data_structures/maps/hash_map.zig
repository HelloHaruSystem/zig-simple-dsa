const std = @import("std");
const LinkedList = @import("../linked_lists/singly_linked_list.zig").SinglyLinkedList;

/// A simple implementation of a hash map.
/// default capacity is 16 and it uses std.Wyhash for hashing
pub fn HashMap(comptime key_type: type, comptime value_type: type) type {
    return struct {
        const Self = @This();

        // fields
        /// The allocator used to allocate the memory needed by the hash map
        allocator: std.mem.Allocator,
        /// The buckets holding the entries of the hash map
        /// This is a singly linked list that can hold multiple entries in case of a collision
        buckets: []LinkedList(Entry),
        /// Capactiy of the hash map
        /// Defaults to 16 but expands when the number of entries / capacity exceeds 0.75
        capacity: usize,
        /// The number of entries into the hash map
        count: usize,

        /// Initilaizes an empty hash map
        /// Initiliazes the default 16 buckets(singly linked list) open first initilazation
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

        /// Frees the memory used by the hash map
        pub fn deinit(self: *Self) void {
            for (self.buckets) |*bucket| {
                bucket.deinit();
            }

            self.allocator.free(self.buckets);
        }

        /// Internal hash function
        /// Using std.Wyhash to hash the keys
        fn hash(key: key_type) u64 {
            // using 0 as seed (mostly to make testing easier)
            // consider using std.crypto.random.int(u64) in the future
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);

            return hasher.final();
        }

        /// Internal function that checks for equal keys
        /// using std.meta.eql()
        fn keysEqual(key_a: key_type, key_b: key_type) bool {
            return std.meta.eql(key_a, key_b);
        }

        /// Internal function to check if the hash map needs to expand it's capacity
        fn checkLoadFactor(self: *Self) bool {
            if (self.count == 0) return false;
            const load_factor = @as(f64, @floatFromInt(self.count)) / @as(f64, @floatFromInt(self.capacity));

            if (load_factor >= 0.75) {
                return true;
            }

            return false;
        }

        /// Internal function that expands the current capactiy *2 of the hashmap
        /// It also rehashes the current entries
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
        // TODO: TEST TEST TEST :)

        // a entry for the bucket containing a key and value pair
        const Entry = struct {
            key: key_type,
            value: value_type,
        };
    };
}
