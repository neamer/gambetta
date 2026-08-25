const rl = @import("raylib");

pub fn main() anyerror!void {

    const screen_width = 800;
    const screen_height = 450;

    rl.initWindow(screen_width, screen_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(360);

    const img = rl.genImageColor(screen_width, screen_height, .black);
    const tex = try rl.loadTextureFromImage(img);
    rl.unloadImage(img);
    defer rl.unloadTexture(tex);

    var pixels: [screen_width * screen_height]rl.Color = @splat(rl.Color.white);

    var idx: usize = 0;
    var override_color: rl.Color = .blue;
    const stroke = 50;

    while (!rl.windowShouldClose()) {

        fillColumn(&pixels, idx, screen_width, stroke, override_color);

        idx += 1;

        if (idx % screen_width == 0) {
            if (idx < pixels.len - (stroke - 1) * screen_width) {
                idx += screen_width * (stroke - 1);
            } else {
                idx = 0;
                override_color = .red;
            }
        }

        rl.updateTexture(tex, &pixels);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.dark_gray);
        rl.drawTexture(tex, 0, 0, .white);
    }
}

fn fillColumn(pixels: []rl.Color, idx: usize, screen_width: usize, comptime stroke: usize, color: rl.Color) void {
    inline for (0..stroke) |i| {
        pixels[idx + screen_width * i] = color;
    }
}
