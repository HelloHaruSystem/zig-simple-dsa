const std = @import("std");

// algorithims
pub const algorithms = @import("algorithms/mod.zig");

// data structures
pub const arrays = @import("data_structures/arrays/mod.zig");
pub const lists = @import("data_structures/linked_lists/mod.zig");
pub const queues = @import("data_structures/queues/mod.zig");
pub const stacks = @import("data_structures/stacks/mod.zig");
pub const maps = @import("data_structures/maps/mod.zig");

// Convenience re-exports for common types add here

test {
    std.testing.refAllDeclsRecursive(@This());
}
