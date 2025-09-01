const std = @import("std");
const testing = std.testing;

pub const Searching = struct {
    // time complexity worst case O(n)
    // space complexity O(1)
    pub fn linearSearch(comptime T: type, arr: []const T, target: T) ?usize {
        for (arr, 0..) |number, i| {
            if (number == target) {
                return i;
            }
        }
        return null;
    }

    // time complexity worst case O(log n)
    // space complexity O(1)
    pub fn binarySearch(comptime T: type, arr: []const T, target: T) ?usize {
        if (arr.len == 0) return null;

        var start: usize = 0;
        var end: usize = arr.len - 1;

        while (start <= end) {
            const mid: usize = start + ((end - start) / 2);

            if (arr[mid] == target) {
                return mid;
            }

            if (target < arr[mid]) {
                if (mid == 0) break;
                end = mid - 1;
            } else {
                start = mid + 1;
            }
        }

        return null;
    }
};

// tests
// binary search
test "binary search basic funtionality" {
    const sorted_array = [_]i32{ 11, 12, 22, 25, 34, 64, 90 };
    const target_number = 64;
    const expected_index: usize = 5;

    const output = Searching.binarySearch(i32, sorted_array[0..], target_number);

    try testing.expectEqual(expected_index, output);
}

test "binary search on empty array" {
    const empty_array = [_]u8{};
    const not_present_target: u8 = 0;

    const output: ?usize = Searching.binarySearch(u8, empty_array[0..], not_present_target);

    try testing.expectEqual(null, output);
}

test "binary search target not in array" {
    const sorted_array = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const not_present_target: u8 = 13;

    const output: ?usize = Searching.binarySearch(u8, sorted_array[0..], not_present_target);

    try testing.expectEqual(null, output);
}

test "binary search non present target is lower then first number in array" {
    const sorted_array = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const not_present_target: u8 = 9;

    const output: ?usize = Searching.binarySearch(u8, sorted_array[0..], not_present_target);

    try testing.expectEqual(null, output);
}

test "binary search non present target is higher then last number in array" {
    const sorted_array = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const not_present_target: u8 = 255;

    const output: ?usize = Searching.binarySearch(u8, sorted_array[0..], not_present_target);

    try testing.expectEqual(null, output);
}

test "binary search single element valid target" {
    const one_element_array = [_]i8{27};
    const target: i8 = 27;
    const expected: ?usize = 0;

    const output: ?usize = Searching.binarySearch(i8, one_element_array[0..], target);

    try testing.expectEqual(expected, output);
}

test "binary search two elements valid target" {
    const two_index_sorted_array = [_]i32{ 10, 20 };
    const target: i32 = 10;
    const expected: ?usize = 0;

    const output = Searching.binarySearch(i32, two_index_sorted_array[0..], target);

    try testing.expectEqual(expected, output);
}

// Linear search
test "linear search basic funtionality" {
    const array = [_]u8{ 98, 76, 3, 34, 45, 12, 34, 255, 12 };
    const target: u8 = 255;
    const expected_index: ?usize = 7;

    const output = Searching.linearSearch(u8, array[0..], target);

    try testing.expectEqual(expected_index, output);
}

test "linear search on empty array" {
    const array = [_]i64{};
    const target = 0;
    const expected_result: ?usize = null;

    const output = Searching.linearSearch(i64, array[0..], target);

    try testing.expectEqual(expected_result, output);
}

test "linear search target not in array" {
    const array = [_]u16{ 98, 76, 3, 34, 45, 12, 34, 255, 12 };
    const target: u16 = 2;
    const expected_result: ?usize = null;

    const output = Searching.linearSearch(u16, array[0..], target);

    try testing.expectEqual(expected_result, output);
}
