const std = @import("std");
const rl = @import("raylib");

const constants = @import("constants.zig");
const Canvas = @import("canvas.zig").Canvas;
const Scene = @import("scene.zig").Scene;
const Sphere = @import("scene.zig").Sphere;

const Vector3 = rl.Vector3;

pub fn main(init: std.process.Init) anyerror!void {
    rl.initWindow(constants.canvas_width, constants.canvas_height, "Raytracer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var canvas: Canvas = try .init(init.gpa);
    defer canvas.deinit(init.gpa);

    const origin = Vector3.zero();

    var scene = Scene{};
    try scene.default(init.gpa);
    defer scene.deinit(init.gpa);

    while (!rl.windowShouldClose()) {
        var x: i32 = -constants.canvas_width / 2;
        while (x < constants.canvas_width / 2) : (x += 1) {
            var y: i32 = -constants.canvas_height / 2;
            while (y < constants.canvas_height / 2) : (y += 1) {
                const ray = viewport(x, y);
                const color = traceRay(&scene, origin, ray, constants.viewport_distance, std.math.floatMax(f32));
                canvas.putPixel(x, y, color);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        canvas.draw();
    }
}

fn viewport(x: i32, y: i32) Vector3 {
    return Vector3{
        .x = @as(f32, @floatFromInt(x)) * constants.viewport_width / constants.canvas_width,
        .y = @as(f32, @floatFromInt(y)) * constants.viewport_height / constants.canvas_height,
        .z = constants.viewport_distance,
    };
}

fn closestIntersection(scene: *const Scene, origin: Vector3, ray: Vector3, t_min: f32, t_max: f32) struct { ?Sphere, f32 } {
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

    return .{ closest_sphere, closest_t };
}

fn traceRay(scene: *const Scene, origin: Vector3, ray: Vector3, t_min: f32, t_max: f32) rl.Color {
    const closest_sphere, const closest_t = closestIntersection(scene, origin, ray, t_min, t_max);

    if (closest_sphere == null) {
        return constants.bg_color;
    }

    const position = Vector3.add(origin, Vector3.scale(ray, closest_t));
    const normal = Vector3.normalize(Vector3.subtract(position, closest_sphere.?.center));
    return multiplyColor(
        closest_sphere.?.color,
        computeLighting(scene, position, normal, Vector3.negate(ray), closest_sphere.?.specular)
    );
}

fn multiplyColor(color: rl.Color, scalar: f32) rl.Color {
    return .{
        .r = scaleChannel(color.r, scalar),
        .g = scaleChannel(color.g, scalar),
        .b = scaleChannel(color.b, scalar),
        .a = color.a,
    };
}

fn scaleChannel(channel: u8, scalar: f32) u8 {
    const scaled = @as(f32, @floatFromInt(channel)) * scalar;
    return @intFromFloat(std.math.clamp(scaled, 0, 255));
}

fn intersectRaySphere(origin: Vector3, ray: Vector3, sphere: Sphere) struct { f32, f32 } {
    const r = sphere.radius;
    const CO = Vector3.subtract(origin, sphere.center);

    const a = Vector3.dotProduct(ray, ray);
    const b = 2 * Vector3.dotProduct(CO, ray);
    const c = Vector3.dotProduct(CO, CO) - r * r;

    const discriminant = b * b - 4 * a * c;

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

fn computeLighting(scene: *const Scene, position: Vector3, normal: Vector3, v_direction: Vector3, specular_ex: f32) f32 {
    var i: f32 = 0;

    for (scene.lights.items) |light| {
        switch (light.kind) {
            .ambient => {
                i += light.intensity;
            },
            .point, .directional => {
                var L: Vector3 = undefined;
                var t_max: f32 = undefined;

                switch (light.kind) {
                    .point => {
                        L = Vector3.subtract(light.kind.point.position, position);
                        t_max = 1;
                    },
                    .directional => {
                        L = light.kind.directional.direction;
                        t_max = std.math.floatMax(f32);
                    },
                    else => unreachable,
                }

                // shadows
                const shadow_sphere, _ = closestIntersection(scene, position, L, 0.001, t_max);
                if (shadow_sphere != null) {
                    continue;
                }

                // diffuse
                const n_dot_l = Vector3.dotProduct(normal, L);
                if (n_dot_l > 0) {
                    i += light.intensity * n_dot_l / (Vector3.length(normal) * Vector3.length(L));
                }

                // specular
                if (specular_ex != -1) {
                    const reflection_direction = Vector3.subtract(Vector3.scale(normal, 2 * Vector3.dotProduct(normal, L)), L);
                    const r_dot_v = Vector3.dotProduct(reflection_direction, v_direction);

                    if (r_dot_v > 0) {
                        i += light.intensity *
                            std.math.pow(f32, r_dot_v / (Vector3.length(reflection_direction) * Vector3.length(v_direction)), specular_ex);
                    }
                }
            },
        }
    }

    return i;
}
