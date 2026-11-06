extends Control
## Fondo degradado rosa con corazones que suben flotando.

@export var heart_count: int = 22
@export var burst_mode: bool = false  ## Si es true, lanza una lluvia de corazones (victoria)

var _hearts: Array = []
var _gradient_tex: GradientTexture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Game.COLOR_BG_TOP)
	g.set_color(1, Game.COLOR_BG_BOTTOM)
	_gradient_tex = GradientTexture2D.new()
	_gradient_tex.gradient = g
	_gradient_tex.fill_from = Vector2(0, 0)
	_gradient_tex.fill_to = Vector2(0, 1)
	_gradient_tex.width = 8
	_gradient_tex.height = 256
	for i in heart_count:
		_hearts.append(_new_heart(true))


func _new_heart(random_y: bool) -> Dictionary:
	var s := size if size.x > 0 else Vector2(720, 1280)
	var palette := [Game.COLOR_RED, Game.COLOR_PINK, Game.COLOR_WHITE, Color("#ff758f")]
	var c: Color = palette.pick_random()
	c.a = randf_range(0.25, 0.6)
	return {
		"pos": Vector2(randf() * s.x, randf() * s.y if random_y else s.y + 60.0),
		"size": randf_range(24.0, 70.0),
		"speed": randf_range(30.0, 90.0),
		"phase": randf() * TAU,
		"sway": randf_range(10.0, 40.0),
		"color": c,
	}


func _process(delta: float) -> void:
	for i in _hearts.size():
		var h: Dictionary = _hearts[i]
		var pos: Vector2 = h["pos"]
		pos.y -= h["speed"] * delta * (2.5 if burst_mode else 1.0)
		h["pos"] = pos
		h["phase"] += delta * 1.5
		if pos.y < -80.0:
			_hearts[i] = _new_heart(false)
	queue_redraw()


func burst(amount: int = 40) -> void:
	for i in amount:
		var h := _new_heart(false)
		h["pos"] = Vector2(randf() * size.x, size.y + randf() * 400.0)
		var c: Color = h["color"]
		c.a = randf_range(0.6, 0.95)
		h["color"] = c
		_hearts.append(h)


func _draw() -> void:
	draw_texture_rect(_gradient_tex, Rect2(Vector2.ZERO, size), false)
	for h in _hearts:
		var p: Vector2 = h["pos"] + Vector2(sin(h["phase"]) * h["sway"], 0)
		draw_colored_polygon(Game.heart_points(p, h["size"], 24), h["color"])
