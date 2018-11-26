// http://www.unicode.org/reports/tr44/#General_Category_Values

const std = @import("std");
const assert = std.debug.assert;

pub const GeneralCategory = enum {
    Lu, // Uppercase_Letter: an uppercase letter
    Ll, // Lowercase_Letter: a lowercase letter
    Lt, // Titlecase_Letter: a digraphic character, with first part uppercase
    LC, // Cased_Letter: Lu | Ll | Lt
    Lm, // Modifier_Letter: a modifier letter
    Lo, // Other_Letter: other letters, including syllables and ideographs
    L , // Letter: Lu | Ll | Lt | Lm | Lo
    Mn, // Nonspacing_Mark: a nonspacing combining mark (zero advance width)
    Mc, // Spacing_Mark: a spacing combining mark (positive advance width)
    Me, // Enclosing_Mark: an enclosing combining mark
    M , // Mark: Mn | Mc | Me
    Nd, // Decimal_Number: a decimal digit
    Nl, // Letter_Number: a letterlike numeric character
    No, // Other_Number: a numeric character of other type
    N , // Number: Nd | Nl | No
    Pc, // Connector_Punctuation: a connecting punctuation mark, like a tie
    Pd, // Dash_Punctuation: a dash or hyphen punctuation mark
    Ps, // Open_Punctuation: an opening punctuation mark (of a pair)
    Pe, // Close_Punctuation: a closing punctuation mark (of a pair)
    Pi, // Initial_Punctuation: an initial quotation mark
    Pf, // Final_Punctuation: a final quotation mark
    Po, // Other_Punctuation: a punctuation mark of other type
    P , // Punctuation: Pc | Pd | Ps | Pe | Pi | Pf | Po
    Sm, // Math_Symbol: a symbol of mathematical use
    Sc, // Currency_Symbol: a currency sign
    Sk, // Modifier_Symbol: a non-letterlike modifier symbol
    So, // Other_Symbol: a symbol of other type
    S , // Symbol: Sm | Sc | Sk | So
    Zs, // Space_Separator: a space character (of various non-zero widths)
    Zl, // Line_Separator: U+2028 LINE SEPARATOR only
    Zp, // Paragraph_Separator: U+2029 PARAGRAPH SEPARATOR only
    Z , // Separator: Zs | Zl | Zp
    Cc, // Control: a C0 or C1 control code
    Cf, // Format: a format control character
    Cs, // Surrogate: a surrogate code point
    Co, // Private_Use: a private-use character
    Cn, // Unassigned: a reserved unassigned code point or a noncharacter
    C,  // Other: Cc | Cf | Cs | Co | Cn

    pub fn longName(self: GeneralCategory) []const u8 {
        return switch (self) {
            GeneralCategory.Lu => "Uppercase_Letter",
            GeneralCategory.Ll => "Lowercase_Letter",
            GeneralCategory.Lt => "Titlecase_Letter",
            GeneralCategory.LC => "Cased_Letter",
            GeneralCategory.Lm => "Modifier_Letter",
            GeneralCategory.Lo => "Other_Letter",
            GeneralCategory.L  => "Letter",
            GeneralCategory.Mn => "Nonspacing_Mark",
            GeneralCategory.Mc => "Spacing_Mark",
            GeneralCategory.Me => "Enclosing_Mark",
            GeneralCategory.M  => "Mark",
            GeneralCategory.Nd => "Decimal_Number",
            GeneralCategory.Nl => "Letter_Number",
            GeneralCategory.No => "Other_Number",
            GeneralCategory.N  => "Number",
            GeneralCategory.Pc => "Connector_Punctuation",
            GeneralCategory.Pd => "Dash_Punctuation",
            GeneralCategory.Ps => "Open_Punctuation",
            GeneralCategory.Pe => "Close_Punctuation",
            GeneralCategory.Pi => "Initial_Punctuation",
            GeneralCategory.Pf => "Final_Punctuation",
            GeneralCategory.Po => "Other_Punctuation",
            GeneralCategory.P  => "Punctuation",
            GeneralCategory.Sm => "Math_Symbol",
            GeneralCategory.Sc => "Currency_Symbol",
            GeneralCategory.Sk => "Modifier_Symbol",
            GeneralCategory.So => "Other_Symbol",
            GeneralCategory.S  => "Symbol",
            GeneralCategory.Zs => "Space_Separator",
            GeneralCategory.Zl => "Line_Separator",
            GeneralCategory.Zp => "Paragraph_Separator",
            GeneralCategory.Z  => "Separator",
            GeneralCategory.Cc => "Control",
            GeneralCategory.Cf => "Format",
            GeneralCategory.Cs => "Surrogate",
            GeneralCategory.Co => "Private_Use",
            GeneralCategory.Cn => "Unassigned",
            GeneralCategory.C, => "Other",
        };
    }

    pub fn fromString(str: []const u8) ?GeneralCategory {
        return std.meta.stringToEnum(GeneralCategory, str);
    }
};


test "GeneralCategory" {
    assert(std.mem.eql(u8, "Punctuation", GeneralCategory.fromString("P").?.longName()));
}
