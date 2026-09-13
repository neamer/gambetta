const std = @import("std");
const rl = @import("raylib");

const allocator = @import("gpa.zig").allocator;
const constants = @import("constants.zig");
const draw = @import("draw.zig");
const Model = @import("model.zig").Model;

const ArrayList = std.ArrayList;

const Vector3 = rl.Vector3;
const Vector2 = rl.Vector2;
const Matrix = rl.Matrix;
const Color = rl.Color;

pub const Object = struct {
    model: Model,

    scale: Vector3 = Vector3.one(),
    rotation: Matrix,
    translation: Vector3,

    pub fn init(model: Model, translation: Vector3, scale: Vector3, rotation: Matrix) Object {
        return .{
            .model = model,
            .scale = scale,
            .rotation = rotation,
            .translation = translation,
        };
    }

    pub fn transform(self: Object) Matrix {
        const s_matrix = Matrix.scale(self.scale.x, self.scale.y, self.scale.z);
        const t_matrix = Matrix.translate(self.translation.x, self.translation.y, self.translation.z);

        return Matrix.multiply(Matrix.multiply(s_matrix, self.rotation), t_matrix);
    }
};
