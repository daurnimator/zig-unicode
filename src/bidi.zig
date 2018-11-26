const std = @import("std");

pub const BidiClass = enum {
    // Strong Types
    L,   // Left_To_Right: any strong left-to-right character
    R,   // Right_To_Left: any strong right-to-left (non-Arabic-type) character
    AL,  // Arabic_Letter: any strong right-to-left (Arabic-type) character

    // Weak Types
    EN,  // European_Number: any ASCII digit or Eastern Arabic-Indic digit
    ES,  // European_Separator: plus and minus signs
    ET,  // European_Terminator: a terminator in a numeric format context, includes currency signs
    AN,  // Arabic_Number: any Arabic-Indic digit
    CS,  // Common_Separator: commas, colons, and slashes
    NSM, // Nonspacing_Mark: any nonspacing mark
    BN,  // Boundary_Neutral: most format characters, control codes, or noncharacters

    // Neutral Types
    B,   // Paragraph_Separator: various newline characters
    S,   // Segment_Separator: various segment-related control codes
    WS,  // White_Space: spaces
    ON,  // Other_Neutral: most other symbols and punctuation marks

    // Explicit Formatting Types
    LRE,  // Left_To_Right_Embedding: U+202A: the LR embedding control
    LRO,  // Left_To_Right_Override: U+202D: the LR override control
    RLE,  // Right_To_Left_Embedding: U+202B: the RL embedding control
    RLO,  // Right_To_Left_Override: U+202E: the RL override control
    PDF,  // Pop_Directional_Format: U+202C: terminates an embedding or override control
    LRI,  // Left_To_Right_Isolate: U+2066: the LR isolate control
    RLI,  // Right_To_Left_Isolate: U+2067: the RL isolate control
    FSI,  // First_Strong_Isolate: U+2068: the first strong isolate control
    PDI,  // Pop_Directional_Isolate: U+2069: terminates an isolate control

    pub fn fromString(str: []const u8) ?BidiClass {
        return std.meta.stringToEnum(BidiClass, str);
    }
};
