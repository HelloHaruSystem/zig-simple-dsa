const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // create the DSA library module
    const dsa_module = b.addModule("dsa", .{
        .root_source_file = b.path("src/dsa/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create executable that uses the DSA module
    const exe = b.addExecutable(.{
        .name = "dsa",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "dsa", .module = dsa_module },
            },
        }),
    });

    b.installArtifact(exe);

    // run step
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    // pass in arguments
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // tests for library
    const lib_tests = b.addTest(.{
        .root_module = dsa_module,
    });

    // tsts for the executable
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);
    const run_exe_tests = b.addRunArtifact(exe_tests);

    // test step
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lib_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
