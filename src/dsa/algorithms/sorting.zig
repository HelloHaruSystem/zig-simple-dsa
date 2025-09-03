const std = @import("std");
const testing = std.testing;

pub const Sorting = struct {
    // time complexity worst case O(n^2)
    // space complexity O(1)
    pub fn bubbleSort(comptime T: type, arr: []T) void {
        if (arr.len <= 1) return;

        var swapped = true;
        var n = arr.len;

        while (swapped) {
            swapped = false;

            for (0..n - 1) |i| {
                if (arr[i] > arr[i + 1]) {
                    std.mem.swap(T, &arr[i], &arr[i + 1]);
                    swapped = true;
                }
            }

            n -= 1;
        }
    }

    // time complexity worst case O(n log n)
    // space complexity O(n)
    pub fn mergeSort(allocator: std.mem.Allocator, comptime T: type, arr: []T) !void {
        if (arr.len <= 1) return;

        const n: usize = arr.len;

        const mid_index: usize = n / 2;
        var left_half = try allocator.alloc(T, mid_index);
        var right_half = try allocator.alloc(T, n - mid_index);

        defer allocator.free(left_half);
        defer allocator.free(right_half);

        // fill arrays
        for (arr[0..mid_index], 0..) |number, i| {
            left_half[i] = number;
        }
        for (arr[mid_index..n], 0..) |number, i| {
            right_half[i] = number;
        }

        // divide
        try mergeSort(allocator, T, left_half);
        try mergeSort(allocator, T, right_half);

        // conquer
        merge(T, arr, left_half, right_half);
    }

    // merge function
    // helper functions for merge sort
    fn merge(comptime T: type, original_array: []T, left_array: []T, right_array: []T) void {
        const left_size: usize = left_array.len;
        const right_size: usize = right_array.len;

        var i: usize = 0;
        var j: usize = 0;
        var k: usize = 0;

        while (i < left_size and j < right_size) {
            if (left_array[i] <= right_array[j]) {
                original_array[k] = left_array[i];
                i += 1;
            } else {
                original_array[k] = right_array[j];
                j += 1;
            }

            k += 1;
        }

        // clean-up add remaining elements
        // first check left array
        while (i < left_size) {
            original_array[k] = left_array[i];
            i += 1;
            k += 1;
        }

        // then check right array
        while (j < right_size) {
            original_array[k] = right_array[j];
            j += 1;
            k += 1;
        }
    }
};

// tests
// bubble sort
test "bubbleSort basic functionality" {
    var arr = [_]i32{ 64, 34, 25, 12, 22, 11, 90 };
    const expected = [_]i32{ 11, 12, 22, 25, 34, 64, 90 };

    Sorting.bubbleSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort empty array" {
    var arr = [_]i32{};

    Sorting.bubbleSort(i32, &arr);

    try testing.expectEqualSlices(i32, &[_]i32{}, &arr);
}

test "bubbleSort single element" {
    var arr = [_]i32{42};
    const expected = [_]i32{42};

    Sorting.bubbleSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort already sorted" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const expected = [_]i32{ 1, 2, 3, 4, 5 };

    Sorting.bubbleSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort with duplicates" {
    var arr = [_]i32{ 3, 1, 3, 2, 1 };
    const expected = [_]i32{ 1, 1, 2, 3, 3 };

    Sorting.bubbleSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

// merge sort
test "merge sort basic functionality" {
    const allocator = testing.allocator;

    var unsorted_array = [_]u8{ 64, 34, 25, 12, 22, 11, 90 };
    const expected_array = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };

    try Sorting.mergeSort(allocator, u8, &unsorted_array);

    try testing.expectEqualSlices(u8, &expected_array, &unsorted_array);
}

test "merge sort with empty array" {
    const allocator = testing.allocator;

    var empty_array = [_]i32{};

    try Sorting.mergeSort(allocator, i32, &empty_array);

    try testing.expectEqualSlices(i32, &[_]i32{}, &empty_array);
}

test "merge sort single element" {
    const allocator = testing.allocator;

    var unsorted_array = [_]u8{255};
    const expected_array = [_]u8{255};

    try Sorting.mergeSort(allocator, u8, &unsorted_array);

    try testing.expectEqualSlices(u8, &expected_array, &unsorted_array);
}

test "merge sort already sorted" {
    const allocator = testing.allocator;

    var unsorted_array = [_]u16{ 11, 12, 22, 25, 34, 64, 90 };
    const expected_array = [_]u16{ 11, 12, 22, 25, 34, 64, 90 };

    try Sorting.mergeSort(allocator, u16, &unsorted_array);

    try testing.expectEqualSlices(u16, &expected_array, &unsorted_array);
}

test "merge sort failing allocator" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    var array = [_]u8{ 7, 43, 24, 1, 9, 45 };

    try testing.expectError(error.OutOfMemory, Sorting.mergeSort(allocator, u8, &array));
}
