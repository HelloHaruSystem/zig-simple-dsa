const std = @import("std");
const testing = std.testing;

pub const Sorting = struct {
    // time complexity worst case O(n^2)
    // space complexity O(1)
    pub fn bubbleSort(comptime T: type, arr: []T) void {
        if (arr.len <= 1) return;

        var n: usize = arr.len;

        while (true) {
            var swapped = false;
            var i: usize = 0;

            while (i < n - 1) : (i += 1) {
                if (arr[i] > arr[i + 1]) {
                    const temp = arr[i + 1];
                    arr[i + 1] = arr[i];
                    arr[i] = temp;
                    swapped = true;
                }
            }

            // no swap = array is sorted
            if (!swapped) break;

            n -= 1;
        }
    }

    // time complexity worst case O(n log n)
    // space complexity O(n)
    pub fn mergeSort(allocator: std.mem.Allocator, comptime T: type, arr: []T) !void {
        if (arr.len <= 1) return;

        const n: usize = arr.len;

        const midIndex: usize = n / 2;
        var leftHalf = try allocator.alloc(T, midIndex);
        var rightHalf = try allocator.alloc(T, n - midIndex);

        defer allocator.free(leftHalf);
        defer allocator.free(rightHalf);

        // fill arrays
        for (arr[0..midIndex], 0..) |number, i| {
            leftHalf[i] = number;
        }
        for (arr[midIndex..n], 0..) |number, i| {
            rightHalf[i] = number;
        }

        // divide
        try mergeSort(allocator, T, leftHalf);
        try mergeSort(allocator, T, rightHalf);

        // conquer
        merge(T, arr, leftHalf, rightHalf);
    }

    // merge function
    // helper functions for merge sort
    fn merge(comptime T: type, originalArray: []T, leftArray: []T, rightArray: []T) void {
        const leftSize: usize = leftArray.len;
        const rightSize: usize = rightArray.len;

        var i: usize = 0;
        var j: usize = 0;
        var k: usize = 0;

        while (i < leftSize and j < rightSize) {
            if (leftArray[i] <= rightArray[j]) {
                originalArray[k] = leftArray[i];
                i += 1;
            } else {
                originalArray[k] = rightArray[j];
                j += 1;
            }

            k += 1;
        }

        // clean-up add remaining elements
        // first check left array
        while (i < leftSize) {
            originalArray[k] = leftArray[i];
            i += 1;
            k += 1;
        }

        // then check right array
        while (j < rightSize) {
            originalArray[k] = rightArray[j];
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

    var unsortedArray = [_]u8{ 64, 34, 25, 12, 22, 11, 90 };
    const expectedArray = [_]u8{ 11, 12, 22, 25, 34, 64, 90 };

    try Sorting.mergeSort(allocator, u8, &unsortedArray);

    try testing.expectEqualSlices(u8, &expectedArray, &unsortedArray);
}

test "merge sort with empty array" {
    const allocator = testing.allocator;

    var emptyArray = [_]i32{};

    try Sorting.mergeSort(allocator, i32, &emptyArray);

    try testing.expectEqualSlices(i32, &[_]i32{}, &emptyArray);
}

test "merge sort single element" {
    const allocator = testing.allocator;

    var unsortedArray = [_]u8{255};
    const expectedArray = [_]u8{255};

    try Sorting.mergeSort(allocator, u8, &unsortedArray);

    try testing.expectEqualSlices(u8, &expectedArray, &unsortedArray);
}

test "merge sort already sorted" {
    const allocator = testing.allocator;

    var unsortedArray = [_]u16{ 11, 12, 22, 25, 34, 64, 90 };
    const expectedArray = [_]u16{ 11, 12, 22, 25, 34, 64, 90 };

    try Sorting.mergeSort(allocator, u16, &unsortedArray);

    try testing.expectEqualSlices(u16, &expectedArray, &unsortedArray);
}

test "merge sort failing allocator" {
    var failingAllocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failingAllocator.allocator();

    var array = [_]u8{ 7, 43, 24, 1, 9, 45 };

    try testing.expectError(error.OutOfMemory, Sorting.mergeSort(allocator, u8, &array));
}
