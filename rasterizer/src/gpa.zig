const std = @import("std");

var gpa: std.heap.DebugAllocator(.{}) = .init;
pub const allocator = gpa.allocator();

