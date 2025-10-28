const std = @import("std");
const LinkedList = @import("../linked_lists/singly_linked_list.zig").SinglyLinkedList;
const testing = std.testing;

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

        /// Initializes an empty hash map
        /// Initializes the default 16 buckets(singly linked list) upon first initialization
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
            // check type info to see if the input is a slice
            const type_info = @typeInfo(key_type);

            if (type_info == .pointer and type_info.pointer.size == .slice) {
                return hashSlice(key);
            }
            // using 0 as seed (mostly to make testing easier)
            // consider using std.crypto.random.int(u64) in the future
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);

            return hasher.final();
        }

        /// Inter hash function similiar to the regular hash function
        /// But used to hash strings(slices)
        fn hashSlice(key: key_type) u64 {
            return std.hash.Wyhash.hash(0, key);
        }

        /// Internal function that checks for equal keys
        /// using std.meta.eql()
        /// in case of slices it will use std.mem.eql to compare byte-to-byte
        fn keysEqual(key_a: key_type, key_b: key_type) bool {
            const type_info = @typeInfo(key_type);

            if (type_info == .pointer and type_info.pointer.size == .slice) {
                const child_type = type_info.pointer.child;
                return std.mem.eql(child_type, key_a, key_b);
            }

            return std.meta.eql(key_a, key_b);
        }

        /// Internal function to check if the hash map needs to expand its capacity
        fn checkLoadFactor(self: *Self) bool {
            if (self.count == 0) return false;
            const load_factor = @as(f64, @floatFromInt(self.count)) / @as(f64, @floatFromInt(self.capacity));

            if (load_factor >= 0.75) {
                return true;
            }

            return false;
        }

        /// Internal function that expands the current capacity *2 of the hashmap
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

            // if key doesn't exist already prepend the new entry to the bucket(singly linked list)
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

        /// Internal struct used to hold the key, value pair used in the hashmap
        /// It's generic both for key and value and the Wyhash should be able to hash
        /// more complex structs if they are used as keys if needed
        const Entry = struct {
            key: key_type,
            value: value_type,
        };
    };
}

// tests
test "Hash map init() creates an empty hash map with a capacity of 16, count as 0" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, i32).init(allocator);
    defer hash_map.deinit();

    try testing.expect(hash_map.capacity == 16);
    try testing.expect(hash_map.count == 0);
    // TODO: add isEmpty or more service method when added later
}

test "Hash map init() initializes all the buckets with empty singly linked lists upon initilazation" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, u8).init(allocator);
    defer hash_map.deinit();

    for (hash_map.buckets) |*bucket| {
        try testing.expectEqual(null, bucket.head);
        try testing.expect(bucket.getSize() == 0);
        try testing.expect(bucket.isEmpty());
    }
}

test "hash map deinit() cleans up memory used by the hash map proberly" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, i8).init(allocator);

    try hash_map.put("One", 1);
    try hash_map.put("two", 2);
    try hash_map.put("three", 3);

    hash_map.deinit();
    // the testing allocator will fail this test if there is a memory leak
}
