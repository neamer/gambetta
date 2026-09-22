const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const math = @import("math.zig");
const render = @import("render.zig");
const constants = @import("constants.zig");
const Canvas = @import("canvas.zig").Canvas;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;
const ProjectedPoint = render.ProjectedPoint;
const ScreenPoint = struct { x: usize, y: usize };

pub fn line(canvas: *Canvas, point0: Vector2, point1: Vector2, color: Color) !void {
    const dx = point1.x - point0.x;
    const dy = point1.y - point0.y;

    if (@abs(dx) > @abs(dy)) {
        const from = if (point0.x < point1.x) point0 else point1;
        const to = if (point0.x < point1.x) point1 else point0;

        var ys = try math.interpolate(@round(from.x), from.y, @round(to.x), to.y);
        defer ys.deinit(allocator);

        var x = from.x;
        while (x <= to.x) : (x += 1) {
            canvas.putPixel(@intFromFloat(x), @intFromFloat(@round(ys.items[@intFromFloat(x - from.x)])), color);
        }
    } else {
        const from = if (point0.y < point1.y) point0 else point1;
        const to = if (point0.y < point1.y) point1 else point0;

        var xs = try math.interpolate(@round(from.y), from.x, @round(to.y), to.x);
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

fn pixel(point: ScreenPoint) usize {
    if (point.x < 0 or point.y < 0) return 0;

    return (constants.canvas_height - 1 - point.y) * constants.canvas_width + point.x;
}

fn screen(x: i32, y: i32) ScreenPoint {
    return .{
        .x = @intCast(std.math.clamp(constants.canvas_width / 2 + x, 0, constants.canvas_width - 1)),
        .y = @intCast(std.math.clamp(constants.canvas_height / 2 + y, 0, constants.canvas_height - 1)),
    };
}

pub fn filledTriangle(
    canvas: *Canvas,
    depth_buffer: []f32,
    point0_: ProjectedPoint,
    point1_: ProjectedPoint,
    point2_: ProjectedPoint,
    color: Color) !void {

    var point0 = point0_;
    var point1 = point1_;
    var point2 = point2_;

    if (point1.point.y < point0.point.y) std.mem.swap(ProjectedPoint, &point1, &point0);
    if (point2.point.y < point0.point.y) std.mem.swap(ProjectedPoint, &point2, &point0);
    if (point2.point.y < point1.point.y) std.mem.swap(ProjectedPoint, &point2, &point1);

    var x01 = try math.interpolate(@round(point0.point.y), point0.point.x, @round(point1.point.y), point1.point.x);
    defer x01.deinit(allocator);
    var z01 = try math.interpolate(@round(point0.point.y), point0.inv_z, @round(point1.point.y), point1.inv_z);
    defer z01.deinit(allocator);

    var x12 = try math.interpolate(@round(point1.point.y), point1.point.x, @round(point2.point.y), point2.point.x);
    defer x12.deinit(allocator);
    var z12 = try math.interpolate(@round(point1.point.y), point1.inv_z, @round(point2.point.y), point2.inv_z);
    defer z12.deinit(allocator);

    var x02 = try math.interpolate(@round(point0.point.y), point0.point.x, @round(point2.point.y), point2.point.x);
    defer x02.deinit(allocator);
    var z02 = try math.interpolate(@round(point0.point.y), point0.inv_z, @round(point2.point.y), point2.inv_z);
    defer z02.deinit(allocator);

    _ = x01.pop();
    try x01.appendSlice(allocator, x12.items);
    _ = z01.pop();
    try z01.appendSlice(allocator, z12.items);

    var x_left: std.ArrayList(f32) = undefined;
    var x_right: std.ArrayList(f32) = undefined;

    var z_left: std.ArrayList(f32) = undefined;
    var z_right: std.ArrayList(f32) = undefined;

    const middle = x02.items.len / 2;
    if (x02.items[middle] < x01.items[middle]) {
        x_left = x02;
        x_right = x01;

        z_left = z02;
        z_right = z01;
    } else {
        x_left = x01;
        x_right = x02;

        z_left = z01;
        z_right = z02;
    }

    var y: f32 = @round(point0.point.y);
    while (y <= point2.point.y): (y += 1) {
        const y_diff: usize = @round(y - point0.point.y);

        const x_l = x_left.items[y_diff];
        const x_r = x_right.items[y_diff];

        var z_segment = try math.interpolate(@round(x_l), z_left.items[y_diff], @round(x_r), z_right.items[y_diff]);
        defer z_segment.clearAndFree(allocator);

        var x = x_left.items[y_diff];
        while (x <= x_right.items[y_diff]): (x += 1) {
            const z = z_segment.items[@round(x - x_l)];

            if (z > depth_buffer[pixel(screen(@round(x), @round(y)))]) {
                canvas.putPixel(@round(x), @round(y), color);
                depth_buffer[pixel(screen(@round(x), @round(y)))] = z;
            }
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
    try line(canvas, render.project(vaf), render.project(vbf), .blue);
    try line(canvas, render.project(vbf), render.project(vcf), .blue);
    try line(canvas, render.project(vcf), render.project(vdf), .blue);
    try line(canvas, render.project(vdf), render.project(vaf), .blue);

    // The back face
    try line(canvas, render.project(vab), render.project(vbb), .red);
    try line(canvas, render.project(vbb), render.project(vcb), .red);
    try line(canvas, render.project(vcb), render.project(vdb), .red);
    try line(canvas, render.project(vdb), render.project(vab), .red);

    // The front-to-back edges
    try line(canvas, render.project(vaf), render.project(vab), .green);
    try line(canvas, render.project(vbf), render.project(vbb), .green);
    try line(canvas, render.project(vcf), render.project(vcb), .green);
    try line(canvas, render.project(vdf), render.project(vdb), .green);
}

