const std = @import("std");
const rl = @import("raylib");

const Vector3 = rl.Vector3;

const PointLight = struct {
    position: Vector3,
};

const DirectionalLight = struct {
    direction: Vector3,
};

const Light = struct {
    intensity: f32,
    kind: union(enum) {
        ambient: void,
        point: PointLight,
        directional: DirectionalLight,
    },
};

pub const Sphere = struct {
    center: Vector3,
    radius: f32,
    color: rl.Color,
    specular: f32,
};

pub const Scene = struct {
    spheres: std.ArrayList(Sphere) = .empty,
    lights: std.ArrayList(Light) = .empty,

    pub fn default(self: *Scene, allocator: std.mem.Allocator) !void {
        try self.spheres.append(allocator, .{
            .center = Vector3.init(0, -1, 3),
            .radius = 1,
            .color = .red,
            .specular = 500,
        });
        try self.spheres.append(allocator, .{
            .center = Vector3.init(2, 0, 4),
            .radius = 1,
            .color = .blue,
            .specular = 500,
        });
        try self.spheres.append(allocator, .{
            .center = Vector3.init(-2, 0, 4),
            .radius = 1,
            .color = .green,
            .specular = 10,
        });
        try self.spheres.append(allocator, .{
            .center = Vector3.init(0, -5001, 0),
            .radius = 5000,
            .color = .yellow,
            .specular = 1000,
        });

        try self.lights.append(allocator, .{
            .intensity = 0.2,
            .kind = .{ .ambient = {} }
        });
        try self.lights.append(allocator, .{
            .intensity = 0.6,
            .kind = .{ .point = .{ .position = Vector3.init(2, 1, 0), } }
        });
        try self.lights.append(allocator, .{
            .intensity = 0.2,
            .kind = .{ .directional = .{ .direction = Vector3.init(1, 4, 4), } }
        });
    }

    pub fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        self.spheres.clearAndFree(allocator);
        self.lights.clearAndFree(allocator);
    }
};

