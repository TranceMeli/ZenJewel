# fx.gd
# Small helpers for pixel-style particle effects. Particles are plain squares
# (no texture) so they match the pixel art, and free themselves when done.
class_name FX
extends RefCounted


static func _gradient(colors: Array, offsets: Array = []) -> Gradient:
	var g := Gradient.new()
	if offsets.is_empty():
		for i in range(colors.size()):
			offsets.append(float(i) / max(colors.size() - 1, 1))
	g.offsets = PackedFloat32Array(offsets)
	g.colors  = PackedColorArray(colors)
	return g


static func _shrink() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 0.2))
	return c


## One-shot burst of squares flying out from a point.
static func burst(parent: Node, pos: Vector2, colors: Array, amount: int = 12,
		speed: float = 140.0, size: float = 6.0, lifetime: float = 0.55,
		gravity: float = 420.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position  = pos
	p.emitting  = false
	p.one_shot  = true
	p.explosiveness = 1.0
	p.amount    = amount
	p.lifetime  = lifetime
	p.direction = Vector2.UP
	p.spread    = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity   = Vector2(0, gravity)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.scale_amount_curve = _shrink()
	p.color_ramp         = _gradient([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var initial := _gradient(colors)
	initial.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	p.color_initial_ramp = initial
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.z_index = 20
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.emitting = true
	return p


## Confetti raining down over a horizontal strip.
static func confetti(parent: Node, center: Vector2, width: float, colors: Array) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = center
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.3
	p.amount   = 90
	p.lifetime = 2.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width * 0.5, 4)
	p.direction = Vector2.DOWN
	p.spread    = 25.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity   = Vector2(0, 260)
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 11.0
	p.color_ramp = _gradient([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.7, 1.0])
	var initial := _gradient(colors)
	initial.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	p.color_initial_ramp = initial
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.z_index = 30
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.emitting = true
	return p


## Slow drifting motes (fireflies / pollen) inside a rectangle. Runs forever.
static func ambient(parent: Node, rect: Rect2, color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = rect.get_center()
	p.amount   = 28
	p.lifetime = 7.0
	p.preprocess = 7.0   # start already populated
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect.size * 0.5
	p.direction = Vector2.UP
	p.spread    = 60.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 20.0
	p.gravity   = Vector2.ZERO
	p.scale_amount_min = 3.0
	p.scale_amount_max = 5.0
	var fade := Color(color.r, color.g, color.b, 0.0)
	p.color_ramp = _gradient([fade, color, fade], [0.0, 0.5, 1.0])
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(p)
	return p
