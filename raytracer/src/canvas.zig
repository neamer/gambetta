const std = @import("std");
const rl = @import("raylib");

const constants = @import("constants.zig");
const Scene = @import("scene.zig").Scene;
const Sphere = @import("scene.zig").Sphere;

pub const Canvas = struct {
    texture: rl.Texture2D,
    pixels: []rl.Color,

    fn Point(comptime T: type) type {
        return struct {
            x: T,
            y: T,
        };
    }

    pub fn init(allocator: std.mem.Allocator) !Canvas {
        const img = rl.genImageColor(constants.canvas_width, constants.canvas_height, .black);
        const texture = try rl.loadTextureFromImage(img);
        const pixels = try allocator.alloc(rl.Color, constants.canvas_width * constants.canvas_height);
        @memset(pixels, rl.Color.white);

        rl.unloadImage(img);

        return Canvas{
            .texture = texture,
            .pixels = pixels,
        };
    }

    pub fn deinit(self: *Canvas, allocator: std.mem.Allocator) void {
        rl.unloadTexture(self.texture);
        allocator.free(self.pixels);
    }

    fn pixel(point: Point(usize)) usize {
        if (point.x < 0 or point.y < 0) return 0;

        return (constants.canvas_height - 1 - point.y) * constants.canvas_width + point.x;
    }

    fn screen(x: i32, y: i32) Point(usize) {
        return Point(usize){
            .x = @intCast(std.math.clamp(constants.canvas_width / 2 + x, 0, constants.canvas_width)),
            .y = @intCast(std.math.clamp(constants.canvas_height / 2 + y, 0, constants.canvas_height)),
        };
    }

    pub fn putPixel(self: *Canvas, x: i32, y: i32, color: rl.Color) void {
        self.pixels[pixel(screen(x, y))] = color;
    }

    pub fn draw(self: *Canvas) void {
        rl.updateTexture(self.texture, self.pixels.ptr);
        rl.drawTexture(self.texture, 0, 0, .white);
    }
};
