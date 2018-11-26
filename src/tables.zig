// Parse the official Unicode Tables
// The format is documented at:
// http://www.unicode.org/reports/tr44/#Format_Conventions

const std = @import("std");
const assert = std.debug.assert;
const GeneralCategory = @import("general_category.zig").GeneralCategory;
const BidiClass = @import("bidi.zig").BidiClass;

const Codepoint = u21;

const CanonicalCombiningClass = u8;

const DecompositionTag = enum {
    font,      // Font variant (for example, a blackletter form)
    noBreak,   // No-break version of a space or hyphen
    initial,   // Initial presentation form (Arabic)
    medial,    // Medial presentation form (Arabic)
    final,     // Final presentation form (Arabic)
    isolated,  // Isolated presentation form (Arabic)
    circle,    // Encircled form
    super,     // Superscript form
    sub,       // Subscript form
    vertical,  // Vertical layout presentation form
    wide,      // Wide (or zenkaku) compatibility character
    narrow,    // Narrow (or hankaku) compatibility character
    small,     // Small variant form (CNS compatibility)
    square,    // CJK squared font variant
    fraction,  // Vulgar fraction form
    compat,    // Otherwise unspecified compatibility character

    pub fn fromString(str: []const u8) ?DecompositionTag {
        return std.meta.stringToEnum(DecompositionTag, str);
    }
};

const Decomposition = struct {
    tag: ?DecompositionTag,
    // For historical reasons, the longest compatibility mapping is 18 characters long.
    len: u5,
    value: [18]Codepoint,

    fn format(self: *const Decomposition,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try output(context, "<");
        try std.fmt.formatType(self.tag, fmt, context, Errors, output);
        try output(context, ">");
        for (self.value) |cp, i| {
            if (i == self.len) break;
            // var buf = []u8{0} ** 4;
            // const utf8len = std.unicode.utf8Encode(cp, &buf) catch unreachable;
            // try output(context, buf[0..utf8len]);
            try output(context, " U+");
            try std.fmt.formatType(cp, "X4", context, Errors, output);
        }
    }
};

const Fraction = struct {
    numerator: usize,
    denominator: usize,

    fn format(self: *const Fraction,
        comptime fmt: []const u8,
        context: var,
        comptime Errors: type,
        output: fn (@typeOf(context), []const u8) Errors!void,
    ) Errors!void {
        try std.fmt.formatType(self.numerator, fmt, context, Errors, output);
        try output(context, "/");
        return std.fmt.formatType(self.denominator, fmt, context, Errors, output);
    }
};

const NumericType = enum {
    Decimal,
    Digit,
    Numeric,
};

const NumericValue = union(NumericType) {
    Decimal: usize,
    Digit: usize,
    Numeric: Fraction,
};

const UnicodeDataEntry = struct {
    codepoint: Codepoint,
    name: []const u8,
    general_category: GeneralCategory,
    canonical_combining_class: CanonicalCombiningClass,
    bidi_class: BidiClass,
    decomposition: ?Decomposition,
    numeric: ?NumericValue,
    bidi_mirrored: bool,
    unicode_1_name: []const u8,
    iso_comment: []const u8,
    simple_uppercase_mapping: ?Codepoint,
    simple_lowercase_mapping: ?Codepoint,
    simple_titlecase_mapping: ?Codepoint,
};

// TODO: watch https://github.com/ziglang/zig/issues/1784
const StringIterator = struct {
    buffer: []const u8,
    index: usize,

    pub fn init(buffer: []const u8) StringIterator {
        return StringIterator {
            .buffer = buffer,
            .index = 0,
        };
    }

    pub fn next(self: *StringIterator, terminator: u8) ?[]const u8 {
        const i = self.index;

        if (i == self.buffer.len) {
            return null;
        }

        if (std.mem.indexOfScalarPos(u8, self.buffer, i, terminator)) |e| {
            self.index = e + 1;
            return self.buffer[i..e];
        } else {
            self.index = self.buffer.len;
            return self.buffer[i..];
        }
    }

    /// Returns a slice of the remaining bytes. Does not affect iterator state.
    pub fn rest(self: *const StringIterator) []const u8 {
        return self.buffer[self.index..];
    }
};

const InvalidUnicodeDataLine = error.InvalidUnicodeDataLine;
const UnknownBidiClass = error.UnknownBidiClass;
const UnknownGeneralCategory = error.UnknownGeneralCategory;
const UnknownDecompositionTag = error.UnknownDecompositionTag;

fn parseUnicodeDataEntry(line: []const u8) !UnicodeDataEntry {
    var field_iter = StringIterator.init(line);

    const codepoint = try std.fmt.parseInt(Codepoint, field_iter.next(';') orelse return InvalidUnicodeDataLine, 16);

    const name = field_iter.next(';') orelse return InvalidUnicodeDataLine;

    const general_category = GeneralCategory.fromString(field_iter.next(';') orelse return InvalidUnicodeDataLine) orelse return UnknownGeneralCategory;

    const canonical_combining_class = try std.fmt.parseInt(CanonicalCombiningClass, field_iter.next(';') orelse return InvalidUnicodeDataLine, 10);

    const bidi_class = BidiClass.fromString(field_iter.next(';') orelse return InvalidUnicodeDataLine) orelse return UnknownBidiClass;

    const decomposition: ?Decomposition = decomposition_value: {
        const decomposition_field = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        if (decomposition_field.len == 0) {
            break :decomposition_value null;
        }

        var iter = StringIterator.init(decomposition_field);

        const tag: ?DecompositionTag = tag: {
            if (decomposition_field[0] == '<') {
                iter.index += 1;
                var tmp = iter.next('>') orelse return InvalidUnicodeDataLine;
                _ = iter.next(' ');
                break :tag DecompositionTag.fromString(tmp) orelse return UnknownDecompositionTag;
            } else {
                break :tag null;
            }
        };

        var len = u5(0);
        var value = []Codepoint{0} ** 18;
        while (iter.next(' ')) |cp| {
            value[len] = try std.fmt.parseInt(Codepoint, cp, 16);
            len += 1;
        }

        break :decomposition_value Decomposition {
            .tag = tag,
            .len = len,
            .value = value,
        };
    };

    const numeric: ?NumericValue = numeric_value: {
        const numeric_type_decimal = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        const numeric_type_digit = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        const numeric_type_numeric = field_iter.next(';') orelse return InvalidUnicodeDataLine;

        if (numeric_type_decimal.len != 0) {
            assert(std.mem.eql(u8, numeric_type_decimal, numeric_type_digit));
            assert(std.mem.eql(u8, numeric_type_decimal, numeric_type_numeric));
            break :numeric_value NumericValue {
                .Decimal = try std.fmt.parseInt(usize, numeric_type_decimal, 10),
            };
        } else if (numeric_type_digit.len != 0) {
            assert(std.mem.eql(u8, numeric_type_digit, numeric_type_numeric));
            break :numeric_value NumericValue {
                .Digit = try std.fmt.parseInt(usize, numeric_type_digit, 10),
            };
        } else if (numeric_type_numeric.len != 0) {
            if (std.mem.indexOfScalarPos(u8, numeric_type_numeric, 1, '/')) |frac_pos| {
                // is a fraction
                break :numeric_value NumericValue {
                    .Numeric = Fraction {
                        .numerator = try std.fmt.parseInt(usize, numeric_type_numeric[0..frac_pos], 10),
                        .denominator = try std.fmt.parseInt(usize, numeric_type_numeric[frac_pos+1..], 10),
                    },
                };
            } else {
                break :numeric_value NumericValue {
                    .Numeric = Fraction {
                        .numerator = try std.fmt.parseInt(usize, numeric_type_numeric, 10),
                        .denominator = 1,
                    },
                };
            }
        } else {
            break :numeric_value null;
        }
    };

    const bidi_mirrored: bool = bidi_mirrored: {
        const field = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        assert(field.len == 1);
        if (field[0] == 'Y') {
            break :bidi_mirrored true;
        } else {
            assert(field[0] == 'N');
            break :bidi_mirrored false;
        }
    };

    const unicode_1_name = field_iter.next(';') orelse return InvalidUnicodeDataLine;

    const iso_comment = field_iter.next(';') orelse return InvalidUnicodeDataLine;

    const simple_uppercase_mapping: ?Codepoint = simple_uppercase_mapping: {
        const field = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        break :simple_uppercase_mapping
            if (field.len != 0) try std.fmt.parseInt(Codepoint, field, 16)
            else null;
    };

    const simple_lowercase_mapping: ?Codepoint = simple_lowercase_mapping: {
        const field = field_iter.next(';') orelse return InvalidUnicodeDataLine;
        break :simple_lowercase_mapping
            if (field.len != 0) try std.fmt.parseInt(Codepoint, field, 16)
            else null;
    };

    const simple_titlecase_mapping: ?Codepoint = simple_titlecase_mapping: {
        const field = field_iter.rest();
        break :simple_titlecase_mapping
            if (field.len != 0) try std.fmt.parseInt(Codepoint, field, 16)
            else null;
    };

    return UnicodeDataEntry {
        .codepoint = codepoint,
        .name = name,
        .general_category = general_category,
        .canonical_combining_class = canonical_combining_class,
        .bidi_class = bidi_class,
        .decomposition = decomposition,
        .numeric = numeric,
        .bidi_mirrored = bidi_mirrored,
        .unicode_1_name = unicode_1_name,
        .iso_comment = iso_comment,
        .simple_uppercase_mapping = simple_uppercase_mapping,
        .simple_lowercase_mapping = simple_lowercase_mapping,
        .simple_titlecase_mapping = simple_titlecase_mapping,
    };
}

fn parseUnicodeData(file_contents: []const u8) !void {
    // http://www.unicode.org/reports/tr44/#UnicodeData.txt
    var line_iterator = std.mem.split(file_contents, "\n");
    while (line_iterator.next()) |line| {
        // TODO: collect results
        _ = try parseUnicodeDataEntry(line);
    }
}

test "can parse file" {
    const UnicodeData = parseUnicodeData(@embedFile("../test-data/UCD-11.0.0/UnicodeData.txt"));
}

test "can parse file at compile time" {
    const UnicodeData = comptime parseUnicodeData(@embedFile("../test-data/UCD-11.0.0/UnicodeData.txt"));
}
