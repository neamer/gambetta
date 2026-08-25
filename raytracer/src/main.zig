const std = @import("std");
const rl = @import("raylib");

const screen_width = 800;
const screen_height = 450;

const Canvas = struct {
    texture: rl.Texture2D,
    pixels: [screen_width * screen_height]rl.Color = @splat(rl.Color.white),

    pub const Point = struct {
        x: usize,
        y: usize,
    };

    fn init() !Canvas {
        const img = rl.genImageColor(screen_width, screen_height, .black);
        const texture = try rl.loadTextureFromImage(img);
        rl.unloadImage(img);

        return Canvas {
            .texture = texture,
        };
    }

    fn deinit(self: *Canvas) void {
        rl.unloadTexture(self.texture);
    }

    fn pixel(point: Point) usize {
        if (point.x < 0 or point.y < 0) return 0;

        return point.y * screen_width + point.x;
    }

    fn screen(x: i32, y: i32) Point {
        return Point {
            .x = @intCast(std.math.clamp(screen_width / 2 + x, 0, screen_width)),
            .y = @intCast(std.math.clamp(screen_height / 2 - y, 0, screen_height)),
        };
    }

    fn putPixel(self: *Canvas, x: i32, y: i32, color: rl.Color) void {
        self.pixels[pixel(screen(x, y))] = color;
    }

    fn draw(self: *Canvas) void {
        rl.updateTexture(self.texture, &self.pixels);
        rl.drawTexture(self.texture, 0, 0, .white);
    }
};

pub fn main() anyerror!void {
    rl.initWindow(screen_width, screen_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init();
    defer canvas.deinit();

    canvas.putPixel(-200, -112, .red);

    while (!rl.windowShouldClose()) {

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.dark_gray);
        canvas.draw();
    }
}

