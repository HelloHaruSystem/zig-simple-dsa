const std = @import("std");
const testing = std.testing;

/// A collection of sorting algorithms
pub const Sorting = struct {
    /// Bubble sort algorithm
    /// T must support the > operator
    /// Sorts the array in place
    /// time complexity worst case O(n^2)
    /// space complexity O(1)
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

    /// Merge sort algorithm
    /// T must support the <= operator
    /// Sorts the array in place
    /// Time complexity worst case O(n log n)
    /// Space complexity O(n)
    pub fn mergeSort(allocator: std.mem.Allocator, comptime T: type, arr: []T) !void {
        if (arr.len <= 1) return;

        const n: usize = arr.len;

        const mid_index: usize = n / 2;
        const left_half = try allocator.alloc(T, mid_index);
        const right_half = try allocator.alloc(T, n - mid_index);

        defer allocator.free(left_half);
        defer allocator.free(right_half);

        // fill arrays
        @memcpy(left_half, arr[0..mid_index]);
        @memcpy(right_half, arr[mid_index..n]);

        // divide
        try mergeSort(allocator, T, left_half);
        try mergeSort(allocator, T, right_half);

        // conquer
        merge(T, arr, left_half, right_half);
    }

    /// Merge two sorted arrays into the original array
    /// T must support the <= operator
    /// Helper function for merge sort
    fn merge(comptime T: type, original_array: []T, left_array: []const T, right_array: []const T) void {
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

    /// Quick sort algorithm (Hoare partition scheme)
    /// T must support < or >
    /// Sorts the array in place
    /// Time complexity average O(n log n), worst case O(n^2)
    /// space complexity O(log n) because of the recursion stack
    pub fn quickSort(comptime T: type, arr: []T) void {
        if (arr.len <= 1) return;
        quickSortImpl(T, arr, 0, arr.len - 1);
    }

    fn quickSortImpl(comptime T: type, arr: []T, low: usize, high: usize) void {
        if (low >= high) return;

        const p: usize = partition(T, arr, low, high);
        if (p > 0) quickSortImpl(T, arr, low, p);
        quickSortImpl(T, arr, p + 1, high);
    }

    /// Helper function for quick sort
    fn partition(comptime T: type, arr: []T, low: usize, high: usize) usize {
        const pivot: T = arr[low];
        var i: usize = low;
        var j: usize = high;

        while (true) {
            // move i fowards while arr[i] < pivot
            while (arr[i] < pivot) : (i += 1) {}
            // move j backwards while arr[j] > pivot
            while (arr[j] > pivot) : (j -= 1) {}

            // if the indices cross then the partition is done
            if (i >= j) {
                return j;
            }

            // swap swap the elements at the left and right indices
            // then move the pointers to avoid infinit loop
            std.mem.swap(T, &arr[i], &arr[j]);
            i += 1;
            j -= 1;
        }
    }
};

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

test "quickSort basic functionality" {
    var arr = [_]i32{ 64, 34, 25, 12, 22, 11, 90 };
    const expected = [_]i32{ 11, 12, 22, 25, 34, 64, 90 };

    Sorting.quickSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "quickSort empty array" {
    var arr = [_]i32{};

    Sorting.quickSort(i32, &arr);

    try testing.expectEqualSlices(i32, &[_]i32{}, &arr);
}

test "quickSort single element" {
    var arr = [_]i32{42};
    const expected = [_]i32{42};

    Sorting.quickSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "quickSort already sorted" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const expected = [_]i32{ 1, 2, 3, 4, 5 };

    Sorting.quickSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}

test "quickSort with duplicates" {
    var arr = [_]i32{ 3, 1, 3, 2, 1 };
    const expected = [_]i32{ 1, 1, 2, 3, 3 };

    Sorting.quickSort(i32, &arr);

    try testing.expectEqualSlices(i32, &expected, &arr);
}
