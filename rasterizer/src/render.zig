const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Tri = @import("model.zig").Tri;
const Canvas = @import("canvas.zig").Canvas;
const Scene = @import("scene.zig").Scene;
const Model = @import("model.zig").Model;
const Camera = @import("scene.zig").Camera;

const ArrayList = std.ArrayList;

const Vector2 = rl.Vector2;
const Vector3 = rl.Vector3;
const Matrix = rl.Matrix;
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

pub fn renderObject(canvas: *Canvas, vertices: ArrayList(Vector3), triangles: ArrayList(Tri)) !void {
    var projected: ArrayList(Vector2) = .empty;

    for (vertices.items) |vertex| {
        try projected.append(allocator, project(vertex));
    }

    for (triangles.items) |tri| {
        try renderTriangle(canvas, tri, projected);
    }
}

pub fn renderModel(canvas: *Canvas, model: Model, transform: Matrix) !void {
    var projected: ArrayList(Vector2) = .empty;
    defer projected.deinit(allocator);

    for (model.vertices.items) |vertex| {
        try projected.append(allocator, project(Vector3.transform(vertex, transform)));
    }

    for (model.triangles.items) |tri| {
        try renderTriangle(canvas, tri, projected);
    }
}

fn cameraMatrix(camera: Camera) Matrix {
    const t = Matrix.translate(-camera.translation.x, -camera.translation.y, -camera.translation.z);

    // Undo the camera translation first, then its rotation.
    return Matrix.multiply(t, Matrix.invert(camera.rotation));
}

pub fn renderScene(scene: *Scene, canvas: *Canvas) !void {
    const m_camera = cameraMatrix(scene.camera);

    for (scene.objects.items) |object| {
        const h_matrix = Matrix.multiply(object.transform(), m_camera);
        try renderModel(canvas, object.model, h_matrix);
    }
}

