const std = @import("std");

const Pattern = struct {
    items: []Item,
};

const Item = union(enum) {
    Literal: u8,
    Dot: void,
    CharClass: CharClass,
    Repetition: Repetition,
};

const CharClass = struct {
    negate: bool,
    ranges: []Range,
};

const Range = struct {
    start: u8,
    end: u8,
};

const Repetition = struct {
    item: *Item,
    min: usize,
    max: ?usize,
};

fn parsePattern(allocator: *std.mem.Allocator, pattern: []const u8) !Pattern {
    var items = std.ArrayList(Item).init(allocator);

    var i: usize = 0;
    while (i < pattern.len) {
        const c = pattern[i];
        if (c == '.') {
            try items.append(Item{ .Dot = {} });
        } else if (c == '[') {
            const charClass = try parseCharClass(allocator, pattern[1..]);
            try items.append(Item{ .CharClass = charClass });
            i += charClass.length + 1;
        } else if (c == '*') {
            const lastItem = items.pop() orelse return error.InvalidPattern;
            const newItem = try allocator.create(Item);
            newItem.* = lastItem;
            const repetition = Repetition{
                .item = newItem,
                .min = 0,
                .max = null,
            };
            try items.append(Item{ .Repetition = repetition });
        } else {
            try items.append(Item{ .Literal = c });
        }
        i += 1;
    }

    return Pattern{ .items = items.toSlice() };
}

fn parseCharClass(allocator: *std.mem.Allocator, pattern: []const u8) !CharClass {
    var negate = false;
    var i: usize = 0;
    if (pattern[i] == '^') {
        negate = true;
        i += 1;
    }

    var ranges = std.ArrayList(Range).init(allocator);
    while (i < pattern.len and pattern[i] != ']') {
        const start = pattern[i];
        if (i + 2 < pattern.len and pattern[i + 1] == '-') {
            const end = pattern[i + 2];
            try ranges.append(Range{ .start = start, .end = end });
            i += 3;
        } else {
            try ranges.append(Range{ .start = start, .end = start });
            i += 1;
        }
    }

    return CharClass{ .negate = negate, .ranges = ranges.toSlice() };
}

fn matchPattern(pattern: Pattern, input: []const u8) bool {
    var inputIndex: usize = 0;
    var patternIndex: usize = 0;

    while (patternIndex < pattern.items.len and inputIndex < input.len) {
        const item = pattern.items[patternIndex];
        switch (item) {
            .Literal => {
                if (input[inputIndex] != item.Literal) return false;
                inputIndex += 1;
            },
            .Dot => inputIndex += 1,
            .CharClass => {
                if (!matchCharClass(item.CharClass, input[inputIndex])) return false;
                inputIndex += 1;
            },
            .Repetition => {
                var count: usize = 0;
                while (count < item.Repetition.min) {
                    if (inputIndex >= input.len or !matchItem(item.Repetition.item, input[inputIndex])) {
                        return false;
                    }
                    inputIndex += 1;
                    count += 1;
                }
                while (item.Repetition.max == null or count < item.Repetition.max) {
                    if (inputIndex >= input.len or !matchItem(item.Repetition.item, input[inputIndex])) {
                        break;
                    }
                    inputIndex += 1;
                    count += 1;
                }
            },
        }
        patternIndex += 1;
    }

    return inputIndex == input.len;
}

fn matchCharClass(charClass: CharClass, c: u8) bool {
    var matched = false;
    for (charClass.ranges) |range| {
        if (c >= range.start and c <= range.end) {
            matched = true;
            break;
        }
    }

    if (charClass.negate) {
        return !matched;
    } else {
        return matched;
    }
}

fn matchItem(item: *Item, c: u8) bool {
    switch (item.*) {
        .Literal => return c == item.Literal,
        .Dot => return true,
        .CharClass => return matchCharClass(item.CharClass, c),
        .Repetition => unreachable,
    }
}
