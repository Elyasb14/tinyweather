const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tcp_lib = b.addStaticLibrary(.{ .name = "tcp", .root_source_file = b.path("src/lib/tcp.zig"), .target = target, .optimize = optimize });
    tcp_lib.addCSourceFile(.{ .file = b.path("src/lib/sensors/rg15/rg15.c"), .flags = &.{} });
    tcp_lib.linkLibC();

    const tcp_module = b.addModule("tcp", .{
        .root_source_file = b.path("src/lib/tcp.zig"),
    });
    const handlers_lib = b.addStaticLibrary(.{ .name = "handlers", .root_source_file = b.path("src/lib/handlers.zig"), .target = target, .optimize = optimize });

    const node_exe = b.addExecutable(.{
        .name = "tinyweather-node",
        .root_source_file = b.path("src/node.zig"),
        .target = target,
        .optimize = optimize,
    });

    node_exe.addIncludePath(b.path("src"));
    node_exe.linkLibrary(tcp_lib);
    node_exe.linkLibrary(handlers_lib);

    const proxy_exe = b.addExecutable(.{
        .name = "tinyweather-proxy",
        .root_source_file = b.path("src/proxy.zig"),
        .target = target,
        .optimize = optimize,
    });

    proxy_exe.addIncludePath(b.path("src"));
    proxy_exe.linkLibrary(tcp_lib);
    proxy_exe.linkLibrary(handlers_lib);

    const web_exe = b.addExecutable(.{
        .name = "tinyweather-web",
        .root_source_file = b.path("src/web/server.zig"),
        .target = target,
        .optimize = optimize,
    });

    const bench_exe = b.addExecutable(.{
        .name = "tinyweather-bench",
        .root_source_file = b.path("src/benchmark/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    bench_exe.addIncludePath(b.path("src"));
    bench_exe.linkLibrary(tcp_lib);
    bench_exe.root_module.addIncludePath(b.path("src"));
    bench_exe.root_module.addImport("tcp", tcp_module);

    b.installArtifact(web_exe);
    b.installArtifact(node_exe);
    b.installArtifact(proxy_exe);
    b.installArtifact(bench_exe);
    b.installArtifact(tcp_lib);
    b.installArtifact(handlers_lib);

    const run_node = b.addRunArtifact(node_exe);
    const run_proxy = b.addRunArtifact(proxy_exe);
    const run_web = b.addRunArtifact(web_exe);

    const run_node_step = b.step("run-node", "Run the Tinyweather node server");
    run_node_step.dependOn(&run_node.step);

    const run_proxy_step = b.step("run-proxy", "Run the Tinyweather proxy");
    run_proxy_step.dependOn(&run_proxy.step);

    const run_web_step = b.step("run-web", "Run the Tinyweather web server");
    run_web_step.dependOn(&run_web.step);

    const run_all_step = b.step("run-all", "Run all Tinyweather executables");
    run_all_step.dependOn(&run_node.step);
    run_all_step.dependOn(&run_proxy.step);
    run_all_step.dependOn(&run_web.step);

    const libtcp_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib/tcp.zig"),
        .target = target,
        .optimize = optimize,
    });
    libtcp_unit_tests.addIncludePath(b.path("src"));
    libtcp_unit_tests.linkLibrary(tcp_lib);
    libtcp_unit_tests.linkLibC();

    const helpers_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib/helpers.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(libtcp_unit_tests);
    const run_helpers_unit_tests = b.addRunArtifact(helpers_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_helpers_unit_tests.step);
}
