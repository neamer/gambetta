const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;

const Vector3 = rl.Vector3;

pub fn interpolate(indep_start: i32, dep_start: f32, indep_end: i32, dep_end: f32) !std.ArrayList(f32) {
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

pub const Plane = struct {
    normal: Vector3,
    distance: f32,

    pub fn init(normal: Vector3, distance: f32) Plane {
        const length = @sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);

        return .{
            .normal = .{
                .x = normal.x / length,
                .y = normal.y / length,
                .z = normal.z / length,
            },
            .distance = distance / length,
        };
    }

    pub fn signedDistance(self: Plane, point: Vector3) f32 {
        return self.normal.dotProduct(point) + self.distance;
    }

    pub fn intersectSegment(self: Plane, a: Vector3, b: Vector3) Vector3 {
        const ab = b.subtract(a);

        const t = (-self.distance - self.normal.dotProduct(a)) / self.normal.dotProduct(ab);

        return a.add(ab.scale(t));
    }
};

pub const Sphere = struct {
    center: Vector3,
    radius: f32,
};

