const rl = @import("raylib");

const Plane = @import("math.zig").Plane;

pub const canvas_width = 900;
pub const canvas_height = 900;

pub const viewport_width: f32 = 1;
pub const viewport_height: f32 = 1;
pub const viewport_distance: f32 = 1;

pub const bg_color = rl.Color.init(20, 20, 20, 255);

pub const frustum_planes = [_]Plane{
    Plane.init(.{ .x = 0, .y = 0, .z = 1 }, -viewport_distance), // near
    Plane.init(.{ .x = viewport_distance, .y = 0, .z = viewport_width / 2 }, 0), // left
    Plane.init(.{ .x = -viewport_distance, .y = 0, .z = viewport_width / 2 }, 0), // right
    Plane.init(.{ .x = 0, .y = viewport_distance, .z = viewport_height / 2 }, 0), // bottom
    Plane.init(.{ .x = 0, .y = -viewport_distance, .z = viewport_height / 2 }, 0), // top
};

pub const camera_speed = 2.5;

