const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const Model = @import("model.zig").Model;
const Tri = @import("model.zig").Tri;
const Object = @import("object.zig").Object;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;

pub const Scene = struct {
    objects: ArrayList(Object),

    pub fn init() Scene {
        return .{
            .objects = .empty
        };
    }

    pub fn deinit(self: *Scene) void {
        for(self.objects.items) |*object| {
            object.deinit();
        }
        self.objects.deinit(allocator);
    }

    pub fn firstScene(self: *Scene) !void {
        const vertices = [_]Vector3{
            .{ .x = 1, .y = 1, .z = 1 },
            .{ .x = -1, .y = 1, .z = 1 },
            .{ .x = -1, .y = -1, .z = 1 },
            .{ .x = 1, .y = -1, .z = 1 },
            .{ .x = 1, .y = 1, .z = -1 },
            .{ .x = -1, .y = 1, .z = -1 },
            .{ .x = -1, .y = -1, .z = -1 },
            .{ .x = 1, .y = -1, .z = -1 },
        };

        const triangles = [_]Tri{
            .init(0, 1, 2, .red),
            .init(0, 2, 3, .red),
            .init(4, 0, 3, .green),
            .init(4, 3, 7, .green),
            .init(5, 4, 7, .blue),
            .init(5, 7, 6, .blue),
            .init(1, 5, 6, .yellow),
            .init(1, 6, 2, .yellow),
            .init(4, 5, 1, .purple),
            .init(4, 1, 0, .purple),
            .init(2, 6, 7, .sky_blue),
            .init(2, 7, 3, .sky_blue),
        };

        const cube_model = try Model.init(&vertices, &triangles);

        try self.objects.append(allocator, try Object.init(cube_model, Vector3.init(-1.5, 0, 7)));
        try self.objects.append(allocator, try Object.init(cube_model, Vector3.init(1.2, 1, 6)));
    }
};
