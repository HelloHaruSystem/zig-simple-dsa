pub const sorting = struct {
    pub fn bubble_sort(comptime T: type, arr: []T) void {
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
