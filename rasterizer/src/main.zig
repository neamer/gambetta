const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Canvas = @import("canvas.zig").Canvas;

pub fn main() anyerror!void {
    rl.initWindow(constants.canvas_width, constants.canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init(allocator);
    defer canvas.deinit(allocator);

    try draw.filledTriangle(
        &canvas,
        .{ .x = -200, .y = -200 },
        .{ .x = 50, .y = 220 },
        .{ .x = 200, .y = 20 },
        .red,
    );

    try draw.wireFrameTriangle(
        &canvas,
        .{ .x = -200, .y = -200 },
        .{ .x = 50, .y = 220 },
        .{ .x = 200, .y = 20 },
        .white,
    );

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(constants.bg_color);
        canvas.draw();
    }
}


