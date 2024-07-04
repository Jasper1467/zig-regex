const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const regex_lib = b.addStaticLibrary(.{
        .name = "regex",
        .root_source_file = .{ .path = "src/regex.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(regex_lib);

    const test_exe = b.addExecutable(.{
        .name = "regex_test",
        .root_source_file = .{ .path = "src/test.zig" },
        .target = target,
        .optimize = optimize,
    });

    test_exe.linkLibrary(regex_lib);

    b.installArtifact(test_exe);
}
