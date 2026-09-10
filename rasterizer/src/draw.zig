const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const math = @import("math.zig");
const constants = @import("constants.zig");
const Canvas = @import("canvas.zig").Canvas;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;

pub fn line(canvas: *Canvas, point0: Vector2, point1: Vector2, color: Color) !void {
    const dx = point1.x - point0.x;
    const dy = point1.y - point0.y;

    if (@abs(dx) > @abs(dy)) {
        const from = if (point0.x < point1.x) point0 else point1;
        const to = if (point0.x < point1.x) point1 else point0;

        var ys = try math.interpolate(@intFromFloat(from.x), from.y, @intFromFloat(to.x), to.y);
        defer ys.deinit(allocator);

        var x = from.x;
        while (x <= to.x) : (x += 1) {
            canvas.putPixel(@intFromFloat(x), @intFromFloat(@round(ys.items[@intFromFloat(x - from.x)])), color);
        }
    } else {
        const from = if (point0.y < point1.y) point0 else point1;
        const to = if (point0.y < point1.y) point1 else point0;

        var xs = try math.interpolate(@intFromFloat(from.y), from.x, @intFromFloat(to.y), to.x);
        defer xs.deinit(allocator);

        var y = from.y;
        while (y <= (to.y)) : (y += 1) {
            canvas.putPixel(@intFromFloat(@round(xs.items[@intFromFloat(y - from.y)])), @intFromFloat(y), color);
        }
    }
}

pub fn wireFrameTriangle(canvas: *Canvas, point0: Vector2, point1: Vector2, point2: Vector2, color: Color) !void {
    try line(canvas, point0, point1, color);
    try line(canvas, point1, point2, color);
    try line(canvas, point2, point0, color);
}

pub fn filledTriangle(canvas: *Canvas, point0_: Vector2, point1_: Vector2, point2_: Vector2, color: Color) !void {
    var point0 = point0_;
    var point1 = point1_;
    var point2 = point2_;

    if (point1.y < point0.y) std.mem.swap(Vector2, &point1, &point0);
    if (point2.y < point0.y) std.mem.swap(Vector2, &point2, &point0);
    if (point2.y < point1.y) std.mem.swap(Vector2, &point2, &point1);

    var x01 = try math.interpolate(@intFromFloat(point0.y), point0.x, @intFromFloat(point1.y), point1.x);
    defer x01.deinit(allocator);
    var x12 = try math.interpolate(@intFromFloat(point1.y), point1.x, @intFromFloat(point2.y), point2.x);
    defer x12.deinit(allocator);
    var x02 = try math.interpolate(@intFromFloat(point0.y), point0.x, @intFromFloat(point2.y), point2.x);
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

pub const ShadedPoint = struct {
    pos: Vector2,
    h: f32,
};

pub fn shadedTriangle(canvas: *Canvas, point0_: ShadedPoint, point1_: ShadedPoint, point2_: ShadedPoint, color: Color) !void {
    var point0 = point0_;
    var point1 = point1_;
    var point2 = point2_;

    if (point1.pos.y < point0.pos.y) std.mem.swap(ShadedPoint, &point1, &point0);
    if (point2.pos.y < point0.pos.y) std.mem.swap(ShadedPoint, &point2, &point0);
    if (point2.pos.y < point1.pos.y) std.mem.swap(ShadedPoint, &point2, &point1);

    var x01 = try math.interpolate(@intFromFloat(point0.pos.y), point0.pos.x, @intFromFloat(point1.pos.y), point1.pos.x);
    defer x01.deinit(allocator);
    var h01 = try math.interpolate(@intFromFloat(point0.pos.y), point0.h, @intFromFloat(point1.pos.y), point1.h);
    defer h01.deinit(allocator);

    var x12 = try math.interpolate(@intFromFloat(point1.pos.y), point1.pos.x, @intFromFloat(point2.pos.y), point2.pos.x);
    defer x12.deinit(allocator);
    var h12 = try math.interpolate(@intFromFloat(point1.pos.y), point1.h, @intFromFloat(point2.pos.y), point2.h);
    defer h12.deinit(allocator);

    var x02 = try math.interpolate(@intFromFloat(point0.pos.y), point0.pos.x, @intFromFloat(point2.pos.y), point2.pos.x);
    defer x02.deinit(allocator);
    var h02 = try math.interpolate(@intFromFloat(point0.pos.y), point0.h, @intFromFloat(point2.pos.y), point2.h);
    defer h02.deinit(allocator);

    _ = x01.pop();
    try x01.appendSlice(allocator, x12.items);

    _ = h01.pop();
    try h01.appendSlice(allocator, h12.items);

    var x_left: std.ArrayList(f32) = undefined;
    var x_right: std.ArrayList(f32) = undefined;

    var h_left: std.ArrayList(f32) = undefined;
    var h_right: std.ArrayList(f32) = undefined;

    const middle = x02.items.len / 2;
    if (x02.items[middle] < x01.items[middle]) {
        x_left = x02;
        x_right = x01;

        h_left = h02;
        h_right = h01;
    } else {
        x_left = x01;
        x_right = x02;

        h_left = h01;
        h_right = h02;
    }

    var y: f32 = @round(point0.pos.y);
    while (y <= point2.pos.y): (y += 1) {
        const y_diff: usize = @round(y - point0.pos.y);

        const x_l = x_left.items[y_diff];
        const x_r = x_right.items[y_diff];

        var h_segment = try math.interpolate(@round(x_l), h_left.items[y_diff], @round(x_r), h_right.items[y_diff]);
        defer h_segment.deinit(allocator);

        var x = x_left.items[y_diff];
        while (x <= x_right.items[y_diff]): (x += 1) {
            const shade = h_segment.items[@round(x - x_l)];
            const shaded_color = multiplyColor(color, shade);
            canvas.putPixel(@round(x), @round(y), shaded_color);
        }
    }
}

fn multiplyColor(color: rl.Color, scalar: f32) rl.Color {
    return .{
        .r = scaleChannel(color.r, scalar),
        .g = scaleChannel(color.g, scalar),
        .b = scaleChannel(color.b, scalar),
        .a = color.a,
    };
}

fn scaleChannel(channel: u8, shade: f32) u8 {
    const t = std.math.clamp(shade, 0, 1);
    return @intFromFloat(@round(@as(f32, @floatFromInt(channel)) * t));
}

fn viewportToCanvas(pos: Vector2) Vector2 {
    return .{
        .x = pos.x * constants.canvas_width / constants.viewport_width,
        .y = pos.y * constants.canvas_height / constants.viewport_height,
    };
}

fn project(pos: Vector3) Vector2 {
    return viewportToCanvas(.{
        .x = pos.x * constants.viewport_distance / pos.z,
        .y = pos.y * constants.viewport_distance / pos.z,
    });
}

pub fn cube(canvas: *Canvas) !void {
    // The four "front" vertices
    const vaf = Vector3{ .x = -2, .y = -0.5, .z = 5 };
    const vbf = Vector3{ .x = -2, .y = 0.5, .z = 5 };
    const vcf = Vector3{ .x = -1, .y = 0.5, .z = 5 };
    const vdf = Vector3{ .x = -1, .y = -0.5, .z = 5 };

    // The four "back" vertices
    const vab = Vector3{ .x = -2, .y = -0.5, .z = 6 };
    const vbb = Vector3{ .x = -2, .y = 0.5, .z = 6 };
    const vcb = Vector3{ .x = -1, .y = 0.5, .z = 6 };
    const vdb = Vector3{ .x = -1, .y = -0.5, .z = 6 };

    // The front face
    try line(canvas, project(vaf), project(vbf), .blue);
    try line(canvas, project(vbf), project(vcf), .blue);
    try line(canvas, project(vcf), project(vdf), .blue);
    try line(canvas, project(vdf), project(vaf), .blue);

    // The back face
    try line(canvas, project(vab), project(vbb), .red);
    try line(canvas, project(vbb), project(vcb), .red);
    try line(canvas, project(vcb), project(vdb), .red);
    try line(canvas, project(vdb), project(vab), .red);

    // The front-to-back edges
    try line(canvas, project(vaf), project(vab), .green);
    try line(canvas, project(vbf), project(vbb), .green);
    try line(canvas, project(vcf), project(vcb), .green);
    try line(canvas, project(vdf), project(vdb), .green);
}
