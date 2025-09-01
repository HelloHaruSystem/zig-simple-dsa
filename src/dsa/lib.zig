const sorting = @import("./algorithms/sorting.zig").Sorting;
const searcing = @import("./algorithms/searching.zig").Searching;

// add data structures here
pub const DataStructures = struct {};

// add algorithms here
pub const Algorithms = struct {
    pub const bubble_sort = sorting.bubbleSort;
    pub const binary_search = searcing.binarySearch;
};
