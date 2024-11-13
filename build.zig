const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tcp_lib = b.addStaticLibrary(.{ .name = "tcp", .root_source_file = b.path("src/tcp.zig"), .target = target, .optimize = optimize });
    tcp_lib.addCSourceFile(.{ .file = b.path("src/sensors/rg15.c"), .flags = &.{} });
    tcp_lib.linkLibC();

    const server_exe = b.addExecutable(.{
        .name = "tinyweather-node",
        .root_source_file = b.path("src/node.zig"),
        .target = target,
        .optimize = optimize,
    });

    server_exe.addIncludePath(b.path("src"));
    server_exe.linkLibrary(tcp_lib);

    const client_exe = b.addExecutable(.{
        .name = "tinyweather-client",
        .root_source_file = b.path("src/client.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(server_exe);
    b.installArtifact(client_exe);

    const server_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/node.zig"),
        .target = target,
        .optimize = optimize,
    });

    server_unit_tests.addIncludePath(b.path("src"));
    server_unit_tests.linkLibrary(tcp_lib);
    server_unit_tests.linkLibC();

    const helpers_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/helpers.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(server_unit_tests);
    const run_helpers_unit_tests = b.addRunArtifact(helpers_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_helpers_unit_tests.step);
}
