const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Plane = @import("math.zig").Plane;
const Tri = @import("model.zig").Tri;
const Canvas = @import("canvas.zig").Canvas;
const Scene = @import("scene.zig").Scene;
const Model = @import("model.zig").Model;
const Object = @import("object.zig").Object;
const Camera = @import("scene.zig").Camera;
const RenderMode = @import("scene.zig").RenderMode;

const ArrayList = std.ArrayList;

const Vector2 = rl.Vector2;
const Vector3 = rl.Vector3;
const Matrix = rl.Matrix;
const Color = rl.Color;

pub const ProjectedPoint = struct {
    point: Vector2,
    inv_z: f32,

    pub fn init(point: Vector2, inv_z: f32) ProjectedPoint {
        return .{
            .point = point,
            .inv_z = inv_z,
        };
    }
};

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

pub fn projectWithDepth(pos: Vector3) ProjectedPoint {
    return .{
        .point = viewportToCanvas(.{
            .x = pos.x * constants.viewport_distance / pos.z,
            .y = pos.y * constants.viewport_distance / pos.z,
        }),
        .inv_z = 1 / pos.z,
    };
}

pub fn renderTriangle(canvas: *Canvas, depth_buffer: []f32, mode: RenderMode, tri: Tri, projected: ArrayList(ProjectedPoint)) !void {
    switch (mode) {
        .wireframe => try draw.wireFrameTriangle(
            canvas,
            projected.items[tri.vertices[0]].point,
            projected.items[tri.vertices[1]].point,
            projected.items[tri.vertices[2]].point,
            tri.color
        ),
        .solid => try draw.filledTriangle(
            canvas,
            depth_buffer,
            projected.items[tri.vertices[0]],
            projected.items[tri.vertices[1]],
            projected.items[tri.vertices[2]],
            tri.color
        ),
    }
}

pub fn renderModel(arena: std.mem.Allocator, canvas: *Canvas, depth_buffer: []f32, mode: RenderMode, model: Model) !void {
    var projected: ArrayList(ProjectedPoint) = .empty;

    for (model.vertices.items) |vertex| {
        try projected.append(arena, projectWithDepth(vertex));
    }

    for (model.triangles.items) |tri| {
        try renderTriangle(canvas, depth_buffer, mode, tri, projected);
    }
}

fn cameraMatrix(camera: Camera) Matrix {
    const t = Matrix.translate(-camera.translation.x, -camera.translation.y, -camera.translation.z);

    return Matrix.multiply(t, Matrix.invert(camera.rotation));
}

fn addVertex(arena: std.mem.Allocator, vertices: *ArrayList(Vector3), vertex: Vector3) !usize {
    try vertices.append(arena, vertex);
    return vertices.items.len - 1;
}

fn clipTriangle(
    arena: std.mem.Allocator,
    tri: Tri,
    vertices: *ArrayList(Vector3),
    plane: Plane,
    out: *ArrayList(Tri),
) !void {
    var inside: [3]usize = undefined;
    var outside: [3]usize = undefined;
    var inside_count: usize = 0;
    var outside_count: usize = 0;

    for (0..3) |corner| {
        if (plane.signedDistance(vertices.items[tri.vertices[corner]]) >= 0) {
            inside[inside_count] = corner;
            inside_count += 1;
        } else {
            outside[outside_count] = corner;
            outside_count += 1;
        }
    }

    switch (inside_count) {
        3 => try out.append(arena, tri),
        0 => {},
        1 => {
            const corner_a = inside[0];

            const a = tri.vertices[corner_a];
            const b = tri.vertices[(corner_a + 1) % 3];
            const c = tri.vertices[(corner_a + 2) % 3];

            const pos_a = vertices.items[a];
            const pos_b = vertices.items[b];
            const pos_c = vertices.items[c];

            const b_prime = try addVertex(arena, vertices, plane.intersectSegment(pos_a, pos_b));
            const c_prime = try addVertex(arena, vertices, plane.intersectSegment(pos_a, pos_c));

            try out.append(arena, Tri.init(a, b_prime, c_prime, tri.color));
        },
        2 => {
            const corner_c = outside[0];

            const a = tri.vertices[(corner_c + 1) % 3];
            const b = tri.vertices[(corner_c + 2) % 3];
            const c = tri.vertices[corner_c];

            const pos_a = vertices.items[a];
            const pos_b = vertices.items[b];
            const pos_c = vertices.items[c];

            const a_prime = try addVertex(arena, vertices, plane.intersectSegment(pos_a, pos_c));
            const b_prime = try addVertex(arena, vertices, plane.intersectSegment(pos_b, pos_c));

            try out.append(arena, Tri.init(a, b, a_prime, tri.color));
            try out.append(arena, Tri.init(a_prime, b, b_prime, tri.color));
        },
        else => unreachable,
    }
}

fn clipModelAgainstPlane(arena: std.mem.Allocator, model: *Model, plane: Plane) !void {
    var clipped: ArrayList(Tri) = .empty;

    for (model.triangles.items) |tri| {
        try clipTriangle(arena, tri, &model.vertices, plane, &clipped);
    }

    model.triangles = clipped;
}

fn clipObject(
    arena: std.mem.Allocator,
    object: Object,
    camera: Matrix,
    planes: []const Plane,
) !?Model {
    const matrix = Matrix.multiply(object.transform(), camera);
    const bounds = object.boundsInSpace(matrix);

    for (planes) |plane| {
        if (plane.signedDistance(bounds.center) < -bounds.radius) return null;
    }

    var model = try object.model.clone(arena);
    for (model.vertices.items) |*vertex| {
        vertex.* = Vector3.transform(vertex.*, matrix);
    }

    for (planes) |plane| {
        if (plane.signedDistance(bounds.center) > bounds.radius) continue;

        try clipModelAgainstPlane(arena, &model, plane);
        if (model.triangles.items.len == 0) return null;
    }

    return model;
}

pub fn renderScene(scene: *Scene, canvas: *Canvas) !void {
    var frame_arena = std.heap.ArenaAllocator.init(allocator);
    defer frame_arena.deinit();
    const arena = frame_arena.allocator();

    const m_camera = cameraMatrix(scene.camera);
    const depth_buffer = try arena.alloc(f32, constants.canvas_width * constants.canvas_height);
    @memset(depth_buffer, 0);

    for (scene.objects.items) |object| {
        const clipped = try clipObject(arena, object, m_camera, &constants.frustum_planes) orelse continue;
        try renderModel(arena, canvas, depth_buffer, scene.render_mode, clipped);
    }
}

