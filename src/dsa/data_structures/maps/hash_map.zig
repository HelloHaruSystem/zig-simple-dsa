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
        /// Capacity of the hash map
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

        fn getIndex(self: *const Self, key_hash: u64) usize {
            return @as(usize, key_hash % self.capacity);
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

        /// Inserts a key, value pair into the hash map
        /// This method will overwrite previous value if the same key is given
        /// This will also expand the capacity and rehash the current inserted values if needed
        pub fn put(self: *Self, key: key_type, value: value_type) !void {
            const hashed_key = hash(key);
            const index = self.getIndex(hashed_key);
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

        /// Takes a key as argument and finds the value matching for that key in the hashmap
        /// If no matching key is found in the hash map then this method will return null
        pub fn get(self: *const Self, key: key_type) ?value_type {
            if (self.count == 0) return null;

            const hashed_key = hash(key);
            const index = self.getIndex(hashed_key);

            var current = self.buckets[index].head;

            while (current) |node| {
                const entry = node.data;

                if (keysEqual(entry.key, key)) {
                    return entry.value;
                }

                current = node.next;
            }

            return null;
        }

        /// Removes a key-value pair from the hash map by key
        /// Returns the removed value if the key exists, otherwise returns null
        /// Decrements the count by 1 when a pair is removed
        pub fn remove(self: *Self, key: key_type) ?value_type {
            if (self.count == 0) return null;

            const hashed_key = hash(key);
            const index = self.getIndex(hashed_key);
            var bucket = &self.buckets[index];

            // If the key to remove is the head of the linked list
            if (bucket.head) |head| {
                if (keysEqual(head.data.key, key)) {
                    const value = bucket.popHead().?.value;
                    self.count -= 1;
                    return value;
                }
            }

            // Otherwise
            var current = bucket.head;
            while (current) |node| {
                if (node.next) |next_node| {
                    if (keysEqual(next_node.data.key, key)) {
                        const value = next_node.data.value;
                        _ = bucket.removeAfter(node);
                        self.count -= 1;

                        return value;
                    }
                }

                current = node.next;
            }

            return null;
        }

        /// Returns true if the hash map contains the given key
        /// Otherwise false
        pub fn contains(self: *Self, key: key_type) bool {
            if (self.count == 0) return false;

            const hashed_key = hash(key);
            const index = self.getIndex(hashed_key);
            var current = self.buckets[index].head;

            while (current) |node| {
                if (keysEqual(node.data.key, key)) {
                    return true;
                }

                current = node.next;
            }

            return false;
        }

        pub const Iterator = struct {
            map: *const Self,
            bucket_index: usize,
            current: ?*LinkedList(Entry).Node,

            pub fn next(self: *Iterator) ?Entry {
                while (self.bucket_index < self.map.buckets.len) {
                    if (self.current) |node| {
                        const entry = node.data;
                        self.current = node.next;
                        return entry;
                    }

                    self.bucket_index += 1;
                    if (self.bucket_index < self.map.buckets.len) {
                        self.current = self.map.buckets[self.bucket_index].head;
                    }
                }

                return null;
            }
        };

        pub fn iterator(self: *const Self) Iterator {
            return Iterator{
                .map = self,
                .bucket_index = 0,
                .current = if (self.buckets.len > 0) self.buckets[0].head else null,
            };
        }
        // TODO: Maybe an iterator to iterate over keys and values?

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

test "Hash map init() initializes all the buckets with empty singly linked lists upon initialization" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, u8).init(allocator);
    defer hash_map.deinit();

    for (hash_map.buckets) |*bucket| {
        try testing.expectEqual(null, bucket.head);
        try testing.expect(bucket.getSize() == 0);
        try testing.expect(bucket.isEmpty());
    }
}

test "hash map deinit() cleans up memory used by the hash map properly" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, i8).init(allocator);

    try hash_map.put("One", 1);
    try hash_map.put("two", 2);
    try hash_map.put("three", 3);

    hash_map.deinit();
    // the testing allocator will fail this test if there is a memory leak
}

test "put method basic functionality" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, []const u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put("one", "two");
    try hash_map.put("two", "three");
    try hash_map.put("three", "four");

    try testing.expect(hash_map.count == 3);
    try testing.expect(hash_map.capacity == 16);
    try testing.expectEqual("two", hash_map.get("one"));
    try testing.expectEqual("three", hash_map.get("two"));
    try testing.expectEqual("four", hash_map.get("three"));
}

test "put method will automatically expand the capacity if needed and old values are still accessable" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(i32, i32).init(allocator);
    defer hash_map.deinit();

    // need to insert 12 unique items to make it expand
    for (0..12) |i| {
        try hash_map.put(@intCast(i), @intCast(i + 1));
    }

    try testing.expect(hash_map.count == 12);
    try testing.expect(hash_map.capacity == 32);

    // test if old values are still accessable
    for (0..12) |i| {
        const key: i32 = @intCast(i);
        const expected_value: i32 = @intCast(i + 1);
        try testing.expectEqual(expected_value, hash_map.get(key).?);
    }
}

test "put method called with empty string as key" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, i32).init(allocator);
    defer hash_map.deinit();

    try hash_map.put("", 2);

    try testing.expectEqual(2, hash_map.get(""));
}

test "put method called with empty string as value" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(i32, []const u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put(2, "");

    try testing.expectEqual("", hash_map.get(2));
}

test "put method with same key overwrites without inserting a new entry" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(i32, []const u8).init(allocator);
    defer hash_map.deinit();
    var counter: usize = 0;

    try hash_map.put(1, "Hej med dig");
    try hash_map.put(1, "Farvel med dig");
    try hash_map.put(2, "Farvel med dig");
    try hash_map.put(2, "Hej med dig");
    // iterate to see if you only find 2 entries
    for (hash_map.buckets) |*bucket| {
        var current = bucket.head;

        while (current) |node| {
            counter += 1;
            current = node.next;
        }
    }

    try testing.expect(hash_map.count == 2);
    try testing.expectEqual("Farvel med dig", hash_map.get(1));
    try testing.expectEqual("Hej med dig", hash_map.get(2));
    try testing.expect(counter == 2);
}

test "get method basic functionality" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u8, []const u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put('w', "up");
    try hash_map.put('s', "down");
    try hash_map.put('a', "left");
    try hash_map.put('d', "right");

    try testing.expectEqual("up", hash_map.get('w'));
    try testing.expectEqual("down", hash_map.get('s'));
    try testing.expectEqual("left", hash_map.get('a'));
    try testing.expectEqual("right", hash_map.get('d'));
}

test "get method returns null when key is not present in the hash map" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u16, i32).init(allocator);
    defer hash_map.deinit();

    try hash_map.put(2, 4);
    try hash_map.put(4, 16);
    try hash_map.put(16, 256);

    try testing.expectEqual(4, hash_map.get(2));
    try testing.expectEqual(16, hash_map.get(4));
    try testing.expectEqual(256, hash_map.get(16));
    try testing.expectEqual(null, hash_map.get(256));
}

test "get returns null on hash map with a count of 0" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u8, i8).init(allocator);
    defer hash_map.deinit();

    try testing.expectEqual(null, hash_map.get(1));
}

test "remove method basic functionality" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(i32, i64).init(allocator);
    defer hash_map.deinit();

    try hash_map.put(32, 64);
    try hash_map.put(64, 128);
    try hash_map.put(128, 256);

    try testing.expect(hash_map.count == 3);
    try testing.expectEqual(64, hash_map.remove(32).?);
    try testing.expect(hash_map.count == 2);
    try testing.expect(!hash_map.contains(32));
    try testing.expectEqual(128, hash_map.remove(64).?);
    try testing.expect(hash_map.count == 1);
    try testing.expect(!hash_map.contains(64));
    try testing.expectEqual(256, hash_map.remove(128).?);
    try testing.expect(hash_map.count == 0);
    try testing.expect(!hash_map.contains(128));
}

test "remove returns null when key isn't found in the hash map" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u8, u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put('a', 'A');
    try hash_map.put('b', 'B');

    try testing.expectEqual('A', hash_map.remove('a').?);
    try testing.expectEqual('B', hash_map.remove('b').?);
    try testing.expectEqual(null, hash_map.remove('c'));
    try testing.expect(!hash_map.contains('a'));
    try testing.expect(!hash_map.contains('b'));
}

test "remove returns null called on an empty hash map" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u8, u8).init(allocator);
    defer hash_map.deinit();

    try testing.expectEqual(null, hash_map.remove('x'));
    try testing.expect(hash_map.count == 0);
}

test "Calling get method after remove returns null" {
    const allocator = testing.allocator;
    var hash_map = try HashMap(u8, []const u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put('s', "Smile");
    _ = hash_map.remove('s');

    try testing.expectEqual(null, hash_map.get('s'));
    try testing.expect(!hash_map.contains('s'));
}

test "contains method basic functionality" {
    const allocator = testing.allocator;
    var hash_map = try HashMap([]const u8, []const u8).init(allocator);
    defer hash_map.deinit();

    try hash_map.put("red", "#FF0000");
    try hash_map.put("blue", "#0000FF");

    try testing.expect(hash_map.contains("red"));
    try testing.expectEqual("#FF0000", hash_map.remove("red").?);
    try testing.expect(!hash_map.contains("red"));
    try testing.expect(hash_map.contains("blue"));
    try testing.expectEqual("#0000FF", hash_map.remove("blue").?);
    try testing.expect(!hash_map.contains("blue"));
}
