const std = @import("std");
const rl = @import("raylib");

const Vector3 = rl.Vector3;

const canvas_width = 600;
const canvas_height = 600;

const viewport_width: f32 = 1;
const viewport_height: f32 = 1;
const viewport_distance: f32 = 1;

const bg_color = rl.Color.init(20, 20, 20, 255);

pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

const Sphere = struct {
    center: Vector3,
    radius: f32,
    color: rl.Color,
};

const Scene = struct {
    spheres: std.ArrayList(Sphere) = .empty,

    fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        self.spheres.clearAndFree(allocator);
    }
};

const Canvas = struct {
    texture: rl.Texture2D,
    pixels: [canvas_width * canvas_height]rl.Color = @splat(rl.Color.white),

    fn init() !Canvas {
        const img = rl.genImageColor(canvas_width, canvas_height, .black);
        const texture = try rl.loadTextureFromImage(img);
        rl.unloadImage(img);

        return Canvas {
            .texture = texture,
        };
    }

    fn deinit(self: *Canvas) void {
        rl.unloadTexture(self.texture);
    }

    fn pixel(point: Point(usize)) usize {
        if (point.x < 0 or point.y < 0) return 0;

        return (canvas_height - 1 - point.y) * canvas_width + point.x;
    }

    fn screen(x: i32, y: i32) Point(usize) {
        return Point(usize) {
            .x = @intCast(std.math.clamp(canvas_width / 2 + x, 0, canvas_width)),
            .y = @intCast(std.math.clamp(canvas_height / 2 + y, 0, canvas_height)),
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


pub fn main(init: std.process.Init) anyerror!void {
    rl.initWindow(canvas_width, canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init();
    defer canvas.deinit();

    const origin = Vector3.zero();

    var scene = Scene{};
    defer scene.deinit(init.gpa);

    try scene.spheres.append(init.gpa, Sphere {
        .center = rl.Vector3.init(0, -1, 3),
        .radius = 1,
        .color = .red,
    });
    try scene.spheres.append(init.gpa, Sphere {
        .center = rl.Vector3.init(2, 0, 4),
        .radius = 1,
        .color = .blue,
    });
    try scene.spheres.append(init.gpa, Sphere {
        .center = rl.Vector3.init(-2, 0, 4),
        .radius = 1,
        .color = .green,
    });

    while (!rl.windowShouldClose()) {

        rl.beginDrawing();
        defer rl.endDrawing();

        var x: i32 = -canvas_width / 2;
        while (x < canvas_width / 2) : (x += 1) {
            var y: i32 = -canvas_height / 2;
            while (y < canvas_height / 2) : (y += 1) {
                const ray = viewport(x, y);

                // std.debug.print("{} - {} - {}\n", .{ray.x, ray.y, ray.z});

                const color = traceRay(&scene, origin, ray, viewport_distance, std.math.floatMax(f32));
                canvas.putPixel(x, y, color);
            }
        }

        canvas.draw();
    }
}


fn viewport(x: i32, y: i32) Vector3 {
    return Vector3 {
        .x = @as(f32, @floatFromInt(x)) * viewport_width / canvas_width,
        .y = @as(f32, @floatFromInt(y)) * viewport_height / canvas_height,
        .z = viewport_distance,
    };
}

fn traceRay(scene: *const Scene, origin: Vector3, ray: Vector3, t_min: f32, t_max: f32) rl.Color {

    var closest_t: f32 = std.math.floatMax(f32);
    var closest_sphere: ?Sphere = null;

    for (scene.spheres.items) |sphere| {
        const t1, const t2 = intersectRaySphere(origin, ray, sphere);

        if (t1 >= t_min and t1 <= t_max and t1 < closest_t) {
            closest_t = t1;
            closest_sphere = sphere;
        }

        if (t2 >= t_min and t2 <= t_max and t2 < closest_t) {
            closest_t = t2;
            closest_sphere = sphere;
        }
    }

    if (closest_sphere == null) {
        return bg_color;
    }

    return closest_sphere.?.color;
}

fn intersectRaySphere(origin: Vector3, ray: Vector3, sphere: Sphere) struct { f32, f32 } {

    const r = sphere.radius;
    const CO = rl.math.vector3Subtract(origin, sphere.center);

    const a = rl.math.vector3DotProduct(ray, ray);
    const b = 2 * rl.math.vector3DotProduct(CO, ray);
    const c = rl.math.vector3DotProduct(CO, CO) - r * r;

    const discriminant = b*b - 4*a*c;

    if (discriminant < 0) {
        return .{
            std.math.floatMax(f32),
            std.math.floatMax(f32),
        };
    }

    return .{
        (-b + std.math.sqrt(discriminant)) / (2 * a),
        (-b - std.math.sqrt(discriminant)) / (2 * a),
    };
}
