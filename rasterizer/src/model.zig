const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Color = rl.Color;

pub const Tri = struct {
    vertices: [3]usize,
    color: Color,

    pub fn init(v0: usize, v1: usize, v2: usize, color: Color) Tri {
        return .{
            .vertices = .{ v0, v1, v2 },
            .color = color,
        };
    }
};

pub const Model = struct {
    vertices: ArrayList(Vector3),
    triangles: ArrayList(Tri),

    pub fn init(vertices: []const Vector3, triangles: []const Tri) !Model {
        var vertices_list: ArrayList(Vector3) = .empty;
        var triangles_list: ArrayList(Tri) = .empty;

        try vertices_list.appendSlice(allocator, vertices);
        try triangles_list.appendSlice(allocator, triangles);

        return .{
            .vertices = vertices_list,
            .triangles = triangles_list,
        };
    }

    pub fn deinit(self: *Model) void {
        self.vertices.deinit(allocator);
        self.triangles.deinit(allocator);
        self.transformed.deinit(allocator);
    }
};

