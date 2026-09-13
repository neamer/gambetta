const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Tri = @import("model.zig").Tri;
const Canvas = @import("canvas.zig").Canvas;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;

fn viewportToCanvas(pos: Vector2) Vector2 {
    return .{
        .x = pos.x * constants.canvas_width / constants.viewport_width,
        .y = pos.y * constants.canvas_height / constants.viewport_height,
    };
}

pub fn project(pos: Vector3) Vector2 {
    return viewportToCanvas(.{
        .x = pos.x * constants.viewport_distance / pos.z,
        .y = pos.y * constants.viewport_distance / pos.z,
    });
}

pub fn renderTriangle(canvas: *Canvas, tri: Tri, projected: ArrayList(Vector2)) !void {
    try draw.wireFrameTriangle(
        canvas,
        projected.items[tri.vertices[0]],
        projected.items[tri.vertices[1]],
        projected.items[tri.vertices[2]],
        tri.color
    );
}

pub fn object(canvas: *Canvas, vertices: ArrayList(Vector3), triangles: ArrayList(Tri)) !void {
    var projected: ArrayList(Vector2) = .empty;

    for (vertices.items) |vertex| {
        try projected.append(allocator, project(vertex));
    }

    for (triangles.items) |tri| {
        try renderTriangle(canvas, tri, projected);
    }
}

