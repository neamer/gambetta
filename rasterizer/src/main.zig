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

    try drawWireFrameTriangle(
        &canvas,
        .{ .x = -200, .y = -200 },
        .{ .x = 50, .y = 220 },
        .{ .x = 200, .y = 20 },
        .black,
    );

    try drawFilledTriangle(
        &canvas,
        .{ .x = -200, .y = -200 },
        .{ .x = 50, .y = 220 },
        .{ .x = 200, .y = 20 },
        .red,
    );

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
    while (i <= indep_end) : (i += 1) {
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
            canvas.putPixel(@intFromFloat(x), @intFromFloat(@round(ys.items[@intFromFloat(x - from.x)])), color);
        }
    } else {
        const from = if (point0.y < point1.y) point0 else point1;
        const to = if (point0.y < point1.y) point1 else point0;

        var xs = try interpolate(@intFromFloat(from.y), from.x, @intFromFloat(to.y), to.x);
        defer xs.deinit(allocator);

        var y = from.y;
        while (y <= (to.y)) : (y += 1) {
            canvas.putPixel(@intFromFloat(@round(xs.items[@intFromFloat(y - from.y)])), @intFromFloat(y), color);
        }
    }
}

fn drawWireFrameTriangle(canvas: *Canvas, point0: Vector2, point1: Vector2, point2: Vector2, color: Color) !void {
    try drawLine(canvas, point0, point1, color);
    try drawLine(canvas, point1, point2, color);
    try drawLine(canvas, point2, point0, color);
}

fn drawFilledTriangle(canvas: *Canvas, point0_: Vector2, point1_: Vector2, point2_: Vector2, color: Color) !void {
    var point0 = point0_;
    var point1 = point1_;
    var point2 = point2_;

    if (point1.y < point0.y) std.mem.swap(Vector2, &point1, &point0);
    if (point2.y < point0.y) std.mem.swap(Vector2, &point2, &point0);
    if (point2.y < point1.y) std.mem.swap(Vector2, &point2, &point1);

    var x01 = try interpolate(@intFromFloat(point0.y), point0.x, @intFromFloat(point1.y), point1.x);
    defer x01.deinit(allocator);
    var x12 = try interpolate(@intFromFloat(point1.y), point1.x, @intFromFloat(point2.y), point2.x);
    defer x12.deinit(allocator);
    var x02 = try interpolate(@intFromFloat(point0.y), point0.x, @intFromFloat(point2.y), point2.x);
    defer x02.deinit(allocator);

    _ = x01.pop();
    try x01.appendSlice(allocator, x12.items);

    var x_left: std.ArrayList(f32) = undefined;
    var x_right: std.ArrayList(f32) = undefined;

    const middle = x02.items.len / 2;
    if (x02.items[middle] < x01.items[middle]) {
        x_left = x02;
        x_right = x01;
    } else {
        x_left = x01;
        x_right = x02;
    }

    var y: f32 = @round(point0.y);
    while (y <= point2.y): (y += 1) {
        const y_diff: usize = @round(y - point0.y);

        var x = x_left.items[y_diff];
        while (x <= x_right.items[y_diff]): (x += 1) {
            canvas.putPixel(@round(x), @round(y), color);
        }
    }
}
