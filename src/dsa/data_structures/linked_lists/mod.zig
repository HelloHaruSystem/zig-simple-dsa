const std = @import("std");

pub const SinglyLinkedList = @import("singly_linked_list.zig").SinglyLinkedList;
pub const DoublyLinkedList = @import("doubly_linked_list.zig").DoublyLinkedList;

// make sure all tests run
test {
    std.testing.refAllDeclsRecursive(@This());
}
