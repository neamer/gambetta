const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
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

    try drawLine(&canvas, .{ .x = -200, .y = -100 }, .{ .x = 250, .y = 120 }, .black);
    try drawLine(&canvas, .{ .x = -50, .y = -200 }, .{ .x = 60, .y = 240 }, .black);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(constants.bg_color);
        canvas.draw();
    }
}

fn interpolate(indep_start: i32, dep_start: f32, indep_end: i32, dep_end: f32) !std.ArrayList(f32) {

    var values: std.ArrayList(f32) = .empty;

    if (indep_start == indep_end) {
        try values.append(allocator, dep_start);
        return values;
    }

    const slope = (dep_end - dep_start) / @as(f32, @floatFromInt(indep_end - indep_start));
    var dependant = dep_start;
 
    var i = indep_start;
    while (i <= indep_end): (i += 1) {
        try values.append(allocator, dependant);
        dependant += slope;
    }

    return values;
}

fn drawLine(canvas: *Canvas, point0: Vector2, point1: Vector2, color: Color) !void {

    const dx = point1.x - point0.x;
    const dy = point1.y - point0.y;

    if (@abs(dx) > @abs(dy)) {
        const from = if (point0.x < point1.x) point0 else point1;
        const to = if (point0.x < point1.x) point1 else point0;

        var ys = try interpolate(@intFromFloat(from.x), from.y, @intFromFloat(to.x), to.y);
        defer ys.deinit(allocator);

        var x = from.x;
        while (x <= to.x) : (x += 1) {
            canvas.putPixel(
                @intFromFloat(x),
                @intFromFloat(@round(ys.items[@intFromFloat(x - from.x)])),
                color
            );
        }
    } else {
        const from = if (point0.y < point1.y) point0 else point1;
        const to = if (point0.y < point1.y) point1 else point0;

        var xs = try interpolate(@intFromFloat(from.y), from.x, @intFromFloat(to.y), to.x);
        defer xs.deinit(allocator);

        var y = from.y;
        while (y <= (to.y)) : (y += 1) {
            canvas.putPixel(
                @intFromFloat(@round(xs.items[@intFromFloat(y - from.y)])),
                @intFromFloat(y),
                color
            );
        }
    }
}

