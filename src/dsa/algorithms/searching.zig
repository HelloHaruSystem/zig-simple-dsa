pub const Searching = struct {
    pub fn binarySearch(comptime T: type, arr: []T, target: T) ?usize {
        if (arr.len == 0) return null;

        var start: usize = 0;
        var end: usize = arr.len - 1;

        while (start <= end) {
            const mid = start + ((end - start) / 2);

            if (arr[mid] == target) {
                return mid;
            }

            if (target < arr[mid]) {
                end = mid - 1;
            } else {
                start = mid + 1;
            }
        }

        return null;
    }
};
