const std = @import("std");

pub const Searching = struct {
    pub fn LinearSearch(comptime T: type, arr: []const T, target: T) ?usize {
        for (arr, 0..) |number, i| {
            if (number == target) {
                return i;
            }
        }
        return null;
    }

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
    const sortedArray = [_]i32{ 11, 12, 22, 25, 34, 64, 90 };
    const targetNumber = 64;
    const expectedIndex: usize = 5;

    const output = Searching.binarySearch(i32, sortedArray[0..], targetNumber);

    try std.testing.expectEqual(expectedIndex, output);
}

test "binary search on empty array" {
    const emptyArray = [_]u8{};
    const notPresentTarget: u8 = 0;

    const output: ?usize = Searching.binarySearch(u8, emptyArray[0..], notPresentTarget);

    try std.testing.expectEqual(null, output);
}

test "binary search target not in array" {
    const sortedArray = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const notPresentTarget: u8 = 13;

    const output: ?usize = Searching.binarySearch(u8, sortedArray[0..], notPresentTarget);

    try std.testing.expectEqual(null, output);
}

test "binary search non present target is lower then first number in array" {
    const sortedArray = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const notPresentTarget: u8 = 9;

    const output: ?usize = Searching.binarySearch(u8, sortedArray[0..], notPresentTarget);

    try std.testing.expectEqual(null, output);
}

test "binary search non present target is higher then last number in array" {
    const sortedArray = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };
    const notPresentTarget: u8 = 255;

    const output: ?usize = Searching.binarySearch(u8, sortedArray[0..], notPresentTarget);

    try std.testing.expectEqual(null, output);
}

test "binary search single element valid target" {
    const oneElementArray = [_]i8{27};
    const target: i8 = 27;
    const expected: ?usize = 0;

    const output: ?usize = Searching.binarySearch(i8, oneElementArray[0..], target);

    try std.testing.expectEqual(expected, output);
}

test "binary search two elements valid target" {
    const twoIndexSortedArray = [_]i32{ 10, 20 };
    const target: i32 = 10;
    const expected: ?usize = 0;

    const output = Searching.binarySearch(i32, twoIndexSortedArray[0..], target);

    try std.testing.expectEqual(expected, output);
}

// Linear search
test "linear search basic funtionality" {
    const array = [_]u8{ 98, 76, 3, 34, 45, 12, 34, 255, 12 };
    const target: u8 = 255;
    const expectedIndex: ?usize = 7;

    const output = Searching.LinearSearch(u8, array[0..], target);

    try std.testing.expectEqual(expectedIndex, output);
}

test "linear search on empty array" {
    const array = [_]i64{};
    const target = 0;
    const expectedResult: ?usize = null;

    const output = Searching.LinearSearch(i64, array[0..], target);

    try std.testing.expectEqual(expectedResult, output);
}

test "linear search target not in array" {
    const array = [_]u16{ 98, 76, 3, 34, 45, 12, 34, 255, 12 };
    const target: u16 = 2;
    const expectedResult: ?usize = null;

    const output = Searching.LinearSearch(u16, array[0..], target);

    try std.testing.expectEqual(expectedResult, output);
}
