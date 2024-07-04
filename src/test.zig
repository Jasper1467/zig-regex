const std = @import("std");

const regex = @import("regex.zig");

pub fn main() !void {}

test "basic regex matching" {
    std.debug.print("basic regex matching:\n");

    var allocator = std.heap.page_allocator;

    const pattern = try regex.parsePattern(&allocator, "a*b.c") catch std.debug.print("1st test failed\n");
    defer pattern.items.deinit();

    try std.testing.expect(regex.matchPattern(pattern, "aaabc")) catch std.debug.print("2nd test failed\n");

    try std.testing.expect(!regex.matchPattern(pattern, "aaacb")) catch std.debug.print("3rd test failed\n");

    try std.testing.expect(regex.matchPattern(pattern, "ab.c")) catch std.debug.print("4th test failed\n");
}

test "character class matching" {
    std.debug.print("character class matching:\n");

    var allocator = std.heap.page_allocator;

    const pattern = try regex.parsePattern(&allocator, "[a-c]*") catch std.debug.print("5th test failed\n");
    defer pattern.items.deinit();

    try std.testing.expect(regex.matchPattern(pattern, "abc")) catch std.debug.print("6th test failed\n");
    try std.testing.expect(!regex.matchPattern(pattern, "abcd")) catch std.debug.print("7th test failed\n");
    try std.testing.expect(regex.matchPattern(pattern, "a")) catch std.debug.print("8th test failed\n");
}
