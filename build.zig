const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // TCP Library
    const tcp_lib = b.addStaticLibrary(.{ .name = "tcp", .root_source_file = b.path("src/lib/tcp.zig"), .target = target, .optimize = optimize });
    tcp_lib.addCSourceFile(.{ .file = b.path("src/lib/sensors/rg15.c"), .flags = &.{} });
    tcp_lib.linkLibC();

    // Server Executable
    const server_exe = b.addExecutable(.{
        .name = "tinyweather-node",
        .root_source_file = b.path("src/node.zig"),
        .target = target,
        .optimize = optimize,
    });
    server_exe.addIncludePath(b.path("src"));
    server_exe.linkLibrary(tcp_lib);

    // Client Executable
    const client_exe = b.addExecutable(.{
        .name = "tinyweather-client",
        .root_source_file = b.path("src/client.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Web Server Executable
    const web_exe = b.addExecutable(.{
        .name = "tinyweather-web",
        .root_source_file = b.path("src/web/server.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Install artifacts
    b.installArtifact(web_exe);
    b.installArtifact(server_exe);
    b.installArtifact(client_exe);

    // Run steps for each executable
    const run_server = b.addRunArtifact(server_exe);
    const run_client = b.addRunArtifact(client_exe);
    const run_web = b.addRunArtifact(web_exe);

    // Create run steps
    const run_server_step = b.step("run-node", "Run the TinyWeather node server");
    run_server_step.dependOn(&run_server.step);

    const run_client_step = b.step("run-client", "Run the TinyWeather client");
    run_client_step.dependOn(&run_client.step);

    const run_web_step = b.step("run-web", "Run the TinyWeather web server");
    run_web_step.dependOn(&run_web.step);

    // Add a step that runs all executables
    const run_all_step = b.step("run-all", "Run all TinyWeather executables");
    run_all_step.dependOn(&run_server.step);
    run_all_step.dependOn(&run_client.step);
    run_all_step.dependOn(&run_web.step);

    // Tests
    const server_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/node.zig"),
        .target = target,
        .optimize = optimize,
    });
    server_unit_tests.addIncludePath(b.path("src"));
    server_unit_tests.linkLibrary(tcp_lib);
    server_unit_tests.linkLibC();

    const helpers_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib/helpers.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(server_unit_tests);
    const run_helpers_unit_tests = b.addRunArtifact(helpers_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_helpers_unit_tests.step);
}
