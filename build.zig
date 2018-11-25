const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const download_UCD = b.addCommand(".", b.env_map, [][]const u8{
        "wget", "-c", "-O", "test-data/UCD-11.0.0.zip", "https://www.unicode.org/Public/11.0.0/ucd/UCD.zip"
    });

    const extract_UCD = b.addCommand(".", b.env_map, [][]const u8{
        "unzip", "-f", "-d", "test-data/UCD-11.0.0", "test-data/UCD-11.0.0.zip"
    });
    extract_UCD.step.dependOn(&download_UCD.step);

    const run_tests = b.addTest("src/index.zig");
    run_tests.step.dependOn(&extract_UCD.step);

    const test_step = b.step("test", "Test the program");
    test_step.dependOn(&run_tests.step);
}
