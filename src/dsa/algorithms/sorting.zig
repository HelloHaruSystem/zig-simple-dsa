const std = @import("std");

pub const Sorting = struct {
    // time complexity worst case O(n^2)
    // space complexity O(1)
    pub fn bubbleSort(comptime T: type, arr: []T) void {
        if (arr.len <= 1) return;

        var n = arr.len;

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
    pub fn mergeSort(allocator: std.mem.Allocator, comptime T: type, arr: []const T) !void {
        const n: usize = arr.len;

        // check if array is empty or a single value
        if (n <= 1) return;

        const midIndex: usize = n / 2;
        var leftHalf = try allocator.alloc(T, midIndex);
        var rightHalf = try allocator.alloc(T, n - midIndex);

        // fill arrays
        for (arr[0..midIndex], 0..) |number, i| {
            leftHalf[i] = number;
        }
        for (arr[midIndex..n], 0..) |number, i| {
            rightHalf[i] = number;
        }
    }
};

// tests
// bubble sort
test "bubbleSort basic functionality" {
    var arr = [_]i32{ 64, 34, 25, 12, 22, 11, 90 };
    const expected = [_]i32{ 11, 12, 22, 25, 34, 64, 90 };

    Sorting.bubbleSort(i32, &arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort empty array" {
    var arr = [_]i32{};

    Sorting.bubbleSort(i32, &arr);

    try std.testing.expectEqualSlices(i32, &[_]i32{}, &arr);
}

test "bubbleSort single element" {
    var arr = [_]i32{42};
    const expected = [_]i32{42};

    Sorting.bubbleSort(i32, &arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort already sorted" {
    var arr = [_]i32{ 1, 2, 3, 4, 5 };
    const expected = [_]i32{ 1, 2, 3, 4, 5 };

    Sorting.bubbleSort(i32, &arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}

test "bubbleSort with duplicates" {
    var arr = [_]i32{ 3, 1, 3, 2, 1 };
    const expected = [_]i32{ 1, 1, 2, 3, 3 };

    Sorting.bubbleSort(i32, &arr);

    try std.testing.expectEqualSlices(i32, &expected, &arr);
}
