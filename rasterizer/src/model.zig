const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const Sphere = @import("math.zig").Sphere;

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

    pub fn clone(self: Model, alloc: std.mem.Allocator) !Model {
        var vertices: ArrayList(Vector3) = .empty;
        var triangles: ArrayList(Tri) = .empty;

        try vertices.appendSlice(alloc, self.vertices.items);
        try triangles.appendSlice(alloc, self.triangles.items);

        return .{
            .vertices = vertices,
            .triangles = triangles,
        };
    }

    pub fn boundingSphere(self: Model) Sphere {
        var min = self.vertices.items[0];
        var max = self.vertices.items[0];

        for (self.vertices.items[1..]) |vertex| {
            min = .{ .x = @min(min.x, vertex.x), .y = @min(min.y, vertex.y), .z = @min(min.z, vertex.z) };
            max = .{ .x = @max(max.x, vertex.x), .y = @max(max.y, vertex.y), .z = @max(max.z, vertex.z) };
        }

        const center = min.add(max).scale(0.5);

        var radius: f32 = 0;
        for (self.vertices.items) |vertex| {
            radius = @max(radius, vertex.subtract(center).length());
        }

        return .{ .center = center, .radius = radius };
    }

    pub fn deinit(self: *Model) void {
        self.vertices.deinit(allocator);
        self.triangles.deinit(allocator);
    }
};
