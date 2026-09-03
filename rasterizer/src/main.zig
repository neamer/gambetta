const std = @import("std");
const rl = @import("raylib");

const constants = @import("constants.zig");
const Canvas = @import("canvas.zig").Canvas;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;

pub fn main(init: std.process.Init) anyerror!void {
    rl.initWindow(constants.canvas_width, constants.canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init(init.gpa);
    defer canvas.deinit(init.gpa);

    // const origin = Vector3.zero();

    // var x: i32 = -constants.canvas_width / 2;
    // while (x < constants.canvas_width / 2) : (x += 1) {
    //     var y: i32 = -constants.canvas_height / 2;
    //     while (y < constants.canvas_height / 2) : (y += 1) {
    //         const color: rl.Color = if (x < 0) .red else .blue;
    //
    //         canvas.putPixel(x, y, color);
    //     }
    // }

    drawLine(&canvas, .{ .x = -200, .y = -100 }, .{ .x = 250, .y = 120 }, .black);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(constants.bg_color);
        canvas.draw();
    }
}

fn drawLine(canvas: *Canvas, point0: Vector2, point1: Vector2, color: Color) void {

    const from = if (point0.x < point1.x) point0 else point1;
    const to = if (point0.x < point1.x) point1 else point0;

    const a = (to.y - from.y) / (to.x - from.x);
    var y = from.y;

    var x = from.x;
    while (x <= (to.x + 1)) : (x += 1) {
        canvas.putPixel(@intFromFloat(x), @intFromFloat(y), color);
        y = y + a;
    }
}

