const std = @import("std");

pub const Sorting = struct {
    pub fn bubbleSort(comptime T: type, arr: []T) void {
        var i: usize = 0;
        var j: usize = undefined;

        while (i < arr.len) : (i += 1) {
            j = 0;
            while (j < arr.len - 1 - i) : (j += 1) {
                if (arr[j] > arr[j + 1]) {
                    const temp = arr[j + 1];
                    arr[j + 1] = arr[j];
                    arr[j] = temp;
                }
            }
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
