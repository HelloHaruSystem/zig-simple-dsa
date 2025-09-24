// algorithims
const sorting_module = @import("./algorithms/sorting.zig");
const searching_module = @import("./algorithms/searching.zig");

// data structures
const singly_linked_list_module = @import("./data_structures/linked_lists/singly_linked_list.zig");
const doubly_linked_list_module = @import("./data_structures/linked_lists/doubly_linked_list.zig");

// Ensure tests are included in compilation
comptime {
    // algorithms
    _ = sorting_module;
    _ = searching_module;

    // data structures
    _ = singly_linked_list_module;
    _ = doubly_linked_list_module;
}

// add data structures here
/// A collection of data structures
pub const DataStructures = struct {
    pub const singly_linked_list = singly_linked_list_module.SinglyLinkedList;
    pub const doubly_linked_list = doubly_linked_list_module.DoublyLinkedList;
};

// add algorithms here
/// A collection of algorithms
pub const Algorithms = struct {
    pub const Sort = sorting_module.Sorting;
    pub const Search = searching_module.Searching;
};
