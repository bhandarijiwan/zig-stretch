const std = @import("std");

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    for(args) | arg, i | {
        std.debug.print("{}: {s} \n", .{i, arg});
    }
    std.log.info("All your codebase are belong to us.\n", .{});
}
