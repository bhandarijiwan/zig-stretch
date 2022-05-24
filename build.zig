const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("stretch", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(.Debug);

    var gen_test: *std.build.LibExeObjStep = b.addTest("test/gentest/main.zig");
    if (b.args) | args |  {
        if (args.len > 0) {
            gen_test = b.addTest(args[0]);
        }
    } 
    gen_test.setBuildMode(.Debug);
    gen_test.addPackage(.{ .name = "stretch" , .path = .{ .path = "src/main.zig" } });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&gen_test.step);

    const gen_test_step = b.step("test:gen", "Run generated tests");
    gen_test_step.dependOn(&gen_test.step);
}
