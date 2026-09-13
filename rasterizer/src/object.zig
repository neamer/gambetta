const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Model = @import("model.zig").Model;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Color = rl.Color;

pub const Object = struct {
    model: Model,
    translation: Vector3,
    vertices: ArrayList(Vector3),

    pub fn init(model: Model, translation: Vector3) !Object {
        var vertices: ArrayList(Vector3) = .empty;
        try vertices.appendSlice(allocator, model.vertices.items);

        var result: Object = .{
            .model = model,
            .translation = translation,
            .vertices = vertices,
        };

        result.transform();

        return result;
    }

    pub fn deinit(self: *Object) void {
        self.vertices.deinit(allocator);
    }

    fn translate(self: *Object) void {
        for (self.vertices.items, 0..) |v, i| {
            self.vertices.items[i] = Vector3.add(v, self.translation);
        }
    }

    pub fn transform(self: *Object) void {
        self.translate();
    }
};
