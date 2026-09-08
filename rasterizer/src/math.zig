const std = @import("std");
const allocator = @import("gpa.zig").allocator;

pub fn interpolate(indep_start: i32, dep_start: f32, indep_end: i32, dep_end: f32) !std.ArrayList(f32) {
    var values: std.ArrayList(f32) = .empty;

    if (indep_start == indep_end) {
        try values.append(allocator, dep_start);
        return values;
    }

    const slope = (dep_end - dep_start) / @as(f32, @floatFromInt(indep_end - indep_start));
    var dependant = dep_start;

    var i = indep_start;
    while (i <= indep_end) : (i += 1) {
        try values.append(allocator, dependant);
        dependant += slope;
    }

    return values;
}

