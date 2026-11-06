extends Control
## Pantalla para elegir la foto del puzle.

const HeartBackground := preload("res://scripts/heart_background.gd")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(HeartBackground.new())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	box.add_child(header)
	var back := Game.make_button("‹", 48)
	back.custom_minimum_size = Vector2(100, 100)
	back.pressed.connect(_on_back)
	header.add_child(back)
	var title := Game.make_label("Elige un recuerdo", 42)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100, 0)
	header.add_child(spacer)

	box.add_child(Game.make_label("Puzle %dx%d" % [Game.grid_size, Game.grid_size], 32, Game.COLOR_RED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	scroll.add_child(grid)

	var photos := Game.get_photos()
	if photos.is_empty():
		var msg := Game.make_label("Aún no hay fotos.\nAñádelas en assets/photos/ ♥", 36)
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.columns = 1
		grid.add_child(msg)
		return

	for i in photos.size():
		grid.add_child(_make_card(photos[i], i + 1))


func _make_card(path: String, number: int) -> Control:
	var card := Button.new()
	card.custom_minimum_size = Vector2(300, 360)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.COLOR_WHITE
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(0.64, 0.07, 0.24, 0.3)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 5)
	sb.set_content_margin_all(14)
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Game.COLOR_PINK
	card.add_theme_stylebox_override("normal", sb)
	card.add_theme_stylebox_override("hover", sb)
	card.add_theme_stylebox_override("pressed", sb_pressed)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.pressed.connect(_on_photo_chosen.bind(path))

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_top = 14
	v.offset_right = -14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	var tex := TextureRect.new()
	tex.texture = Game.load_photo(path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex.clip_contents = true
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tex)

	var done := Game.is_completed(path, Game.grid_size)
	var best := Game.get_best(path, Game.grid_size)
	var caption := "Recuerdo %d" % number
	if done:
		caption = "♥ %d mov · %s" % [best["moves"], Game.format_time(best["time"])]
	var l := Game.make_label(caption, 26, Game.COLOR_RED if done else Game.COLOR_DARK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	return card


func _on_photo_chosen(path: String) -> void:
	Game.selected_photo = path
	get_tree().change_scene_to_file("res://scenes/puzzle.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
