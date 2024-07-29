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
};
