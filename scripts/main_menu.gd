extends Control
## Menú principal de "El juego de Dana".

const HeartBackground := preload("res://scripts/heart_background.gd")

var _size_buttons: Array[Button] = []
var _big_heart: Control
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := HeartBackground.new()
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_bottom", 100)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	margin.add_child(box)

	box.add_child(Game.make_label("El juego de", 56))
	box.add_child(Game.make_label("Dana", 130, Game.COLOR_RED))

	_big_heart = Control.new()
	_big_heart.custom_minimum_size = Vector2(0, 300)
	_big_heart.draw.connect(_draw_big_heart)
	box.add_child(_big_heart)

	box.add_child(Game.make_label("Desliza las piezas y descubre\nnuestros recuerdos ♥", 34))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	box.add_child(Game.make_label("Dificultad", 34))
	var sizes := HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 20)
	sizes.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(sizes)
	for n in [3, 4, 5]:
		var b := Game.make_button("%dx%d" % [n, n], 36)
		b.custom_minimum_size = Vector2(170, 90)
		b.toggle_mode = true
		b.pressed.connect(_on_size_pressed.bind(n))
		sizes.add_child(b)
		_size_buttons.append(b)
	_refresh_sizes()

	var play := Game.make_button("♥  Jugar  ♥", 52)
	play.pressed.connect(_on_play)
	box.add_child(play)


func _process(delta: float) -> void:
	_time += delta
	_big_heart.queue_redraw()


func _draw_big_heart() -> void:
	var beat := 1.0 + 0.08 * pow(abs(sin(_time * 2.4)), 6.0)
	var c := _big_heart.size / 2.0
	var s := 260.0 * beat
	_big_heart.draw_colored_polygon(Game.heart_points(c + Vector2(0, 8), s), Color(0.64, 0.07, 0.24, 0.25))
	_big_heart.draw_colored_polygon(Game.heart_points(c, s), Game.COLOR_RED)
	_big_heart.draw_colored_polygon(Game.heart_points(c, s * 0.82), Color("#ff758f"))
	# Brillo
	_big_heart.draw_circle(c + Vector2(-s * 0.22, -s * 0.18), s * 0.07, Color(1, 1, 1, 0.7))
	# Mini cuadrícula de puzle dentro del corazón
	var cell := s * 0.13
	var origin := c - Vector2(cell * 1.5, cell * 1.2)
	for y in 3:
		for x in 3:
			if x == 2 and y == 2:
				continue
			var r := Rect2(origin + Vector2(x, y) * cell + Vector2(3, 3), Vector2(cell - 6, cell - 6))
			_big_heart.draw_rect(r, Color(1, 1, 1, 0.55))


func _on_size_pressed(n: int) -> void:
	Game.grid_size = n
	Game.save_progress()
	_refresh_sizes()


func _refresh_sizes() -> void:
	for i in _size_buttons.size():
		var n := 3 + i
		_size_buttons[i].button_pressed = (n == Game.grid_size)
		_size_buttons[i].modulate = Color.WHITE if n == Game.grid_size else Color(1, 1, 1, 0.55)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/photo_select.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
