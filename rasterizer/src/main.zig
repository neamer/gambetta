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

    while (!rl.windowShouldClose()) {

        const delta = rl.getFrameTime();

        const up_pressed = rl.isKeyDown(.up) or rl.isKeyDown(.w);
        const right_pressed = rl.isKeyDown(.right) or rl.isKeyDown(.d);
        const down_pressed = rl.isKeyDown(.down) or rl.isKeyDown(.s);
        const left_pressed = rl.isKeyDown(.left) or rl.isKeyDown(.a);
 
        const up_velocity: f32 = if (up_pressed) 1 else 0;
        const right_velocity: f32 = if (right_pressed) 1 else 0;
        const down_velocity: f32 = if (down_pressed) 1 else 0;
        const left_velocity: f32 = if (left_pressed) 1 else 0;

        const x_velocity: f32 = (right_velocity - left_velocity) * constants.camera_speed * delta;
        const z_velocity: f32 = (up_velocity - down_velocity) * constants.camera_speed * delta;

        const camera_transform = rl.Matrix.translate(x_velocity, 0, z_velocity);

        scene.camera.translation = scene.camera.translation.transform(camera_transform);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(constants.bg_color);
        rl.drawFPS(10, 10);

        try render.renderScene(&scene, &canvas);
        canvas.draw();
        canvas.clear();
    }
}

