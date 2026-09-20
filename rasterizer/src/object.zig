const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Model = @import("model.zig").Model;
const Sphere = @import("math.zig").Sphere;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Matrix = rl.Matrix;
const Color = rl.Color;

pub const Object = struct {
    model: Model,
    bounding_sphere: Sphere,

    scale: Vector3 = Vector3.one(),
    rotation: Matrix,
    translation: Vector3,

    pub fn init(model: Model, translation: Vector3, scale: Vector3, rotation: Matrix) Object {
        return .{
            .model = model,
            .bounding_sphere = model.boundingSphere(),
            .scale = scale,
            .rotation = rotation,
            .translation = translation,
        };
    }

    pub fn copy(self: *Object) Object {
        return .{
            .model = self.model,
            .bounding_sphere = self.bounding_sphere,

            .scale = self.scale,
            .rotation = self.rotation,
            .translation = self.translation,
        };
    }

    pub fn transform(self: Object) Matrix {
        const scale_matrix = Matrix.scale(self.scale.x, self.scale.y, self.scale.z);
        const translate_matrix = Matrix.translate(self.translation.x, self.translation.y, self.translation.z);

        return Matrix.multiply(Matrix.multiply(scale_matrix, self.rotation), translate_matrix);
    }

    pub fn boundsInSpace(self: Object, matrix: Matrix) Sphere {
        const max_scale = @max(@abs(self.scale.x), @max(@abs(self.scale.y), @abs(self.scale.z)));

        return .{
            .center = Vector3.transform(self.bounding_sphere.center, matrix),
            .radius = self.bounding_sphere.radius * max_scale,
        };
    }
};

