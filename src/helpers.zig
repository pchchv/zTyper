pub fn lerpf(start: f32, end: f32, t: f32) f32 {
    return (start * (1.0 - t)) + (end * t);
}

pub fn unlerpf(start: f32, end: f32, t: f32) f32 {
    if ((end == t) or (end <= start)) {
        return 1.0;
    }
    return (t - start) / (end - start);
}

pub const Vector2 = struct {
    const Self = @This();
    x: f32 = 0.0,
    y: f32 = 0.0,

    pub fn lerp(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
        };
    }

    /// Suppose that v lies along the line v1-v2 (may be outside the segment).
    /// Then do not check both x and y unlerp.
    /// Just return the first value found.
    pub fn unlerp(v1: Vector2, v2: Vector2, v: Vector2) f32 {
        if (v1.x != v2.x) {
            return unlerpf(v1.x, v2.x, v.x);
        } else if (v1.y != v2.y) {
            return unlerpf(v1.y, v2.y, v.y);
        }
        return 0;
    }
};
