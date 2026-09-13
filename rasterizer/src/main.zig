const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const render = @import("render.zig");
const Canvas = @import("canvas.zig").Canvas;
const Scene = @import("scene.zig").Scene;

pub fn main() anyerror!void {
    rl.initWindow(constants.canvas_width, constants.canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init(allocator);
    defer canvas.deinit(allocator);

    var scene: Scene = .init();
    try scene.firstScene();
    defer scene.deinit();

    for (scene.objects.items) |object| {
        try render.object(&canvas, object.vertices, object.model.triangles);
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(constants.bg_color);
        canvas.draw();
    }
}

