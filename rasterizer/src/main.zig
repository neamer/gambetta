const std = @import("std");
const rl = @import("raylib");

const constants = @import("constants.zig");
const Canvas = @import("canvas.zig").Canvas;

const Vector3 = rl.Vector3;

pub fn main(init: std.process.Init) anyerror!void {
    rl.initWindow(constants.canvas_width, constants.canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init(init.gpa);
    defer canvas.deinit(init.gpa);

    // const origin = Vector3.zero();

    var x: i32 = -constants.canvas_width / 2;
    while (x < constants.canvas_width / 2) : (x += 1) {
        var y: i32 = -constants.canvas_height / 2;
        while (y < constants.canvas_height / 2) : (y += 1) {
            const color: rl.Color = if (x < 0) .red else .blue;

            canvas.putPixel(x, y, color);
        }
    }

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        canvas.draw();
    }
}
