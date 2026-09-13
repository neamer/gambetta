const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
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

pub const Object = struct {
    vertices: ArrayList(Vector3),
    triangles: ArrayList(Tri),
    transformed: ArrayList(Vector3),

    pub fn init(vertices: []const Vector3, triangles: []const Tri) !Object {
        var vertices_list: ArrayList(Vector3) = .empty;
        var triangles_list: ArrayList(Tri) = .empty;
        var transformed_list: ArrayList(Vector3) = .empty;

        try vertices_list.appendSlice(allocator, vertices);
        try triangles_list.appendSlice(allocator, triangles);
        try transformed_list.appendSlice(allocator, vertices);

        return .{
            .vertices = vertices_list,
            .triangles = triangles_list,
            .transformed = transformed_list,
        };
    }

    pub fn deinit(self: *Object) void {
        self.vertices.deinit(allocator);
        self.triangles.deinit(allocator);
        self.transformed.deinit(allocator);
    }

    pub fn translate(self: *Object, vector: Vector3) void {
        for (self.vertices.items, 0..) |v, i| {
            self.transformed.items[i] = Vector3.add(v, vector);
        }
    }
};
