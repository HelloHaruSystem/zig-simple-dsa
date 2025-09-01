const sorting_module = @import("./algorithms/sorting.zig");
const searching_module = @import("./algorithms/searching.zig");

// Ensure tests are included in compilation
comptime {
    _ = sorting_module;
    _ = searching_module;
}

// add data structures here
pub const DataStructures = struct {};

// add algorithms here
pub const Algorithms = struct {
    pub const Sort = sorting_module.Sorting;
    pub const Search = searching_module.Searching;
};
