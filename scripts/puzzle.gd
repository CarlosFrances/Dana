extends Control
## Puzle deslizante: la foto se corta en NxN piezas, se quita una
## y se desordenan. Hay que usar el hueco para volver a formar la foto.

const HeartBackground := preload("res://scripts/heart_background.gd")
const Tile := preload("res://scripts/tile.gd")

const SLIDE_TIME := 0.12
const SWIPE_THRESHOLD := 30.0

var n: int = 3
var board: Array[int] = []      ## board[celda] = id de pieza (-1 = hueco)
var tiles: Dictionary = {}      ## id de pieza -> nodo Tile
var empty_cell: int = 0
var moves: int = 0
var elapsed: float = 0.0
var playing: bool = false
var started: bool = false
var show_numbers: bool = false

var _texture: Texture2D
var _crop: Rect2
var _bg: Control
var _board_holder: Control
var _board: Control
var _preview: TextureRect
var _moves_label: Label
var _time_label: Label
var _numbers_btn: Button
var _win_layer: Control
var _press_pos: Vector2
var _pressing := false
var _animating := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	n = Game.grid_size
	_texture = Game.load_photo(Game.selected_photo)
	if _texture:
		var ts := _texture.get_size()
		var side := minf(ts.x, ts.y)
		_crop = Rect2((ts - Vector2(side, side)) / 2.0, Vector2(side, side))
	_build_ui()
	_new_game()


# ---------------------------------------------------------------- Interfaz

func _build_ui() -> void:
	_bg = HeartBackground.new()
	add_child(_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	margin.add_child(box)

	# Cabecera
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	box.add_child(header)
	var back := Game.make_button("‹", 48)
	back.custom_minimum_size = Vector2(100, 100)
	back.pressed.connect(_go_back)
	header.add_child(back)
	_moves_label = Game.make_label("", 38)
	_moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_moves_label)
	_time_label = Game.make_label("", 38)
	_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_time_label)

	box.add_child(Game.make_label("Forma la foto ♥", 44, Game.COLOR_RED))

	# Tablero (cuadrado, centrado)
	_board_holder = Control.new()
	_board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_holder.resized.connect(_layout_board)
	box.add_child(_board_holder)

	_board = Control.new()
	_board.clip_contents = true
	_board.gui_input.connect(_on_board_input)
	_board.draw.connect(_draw_board_bg)
	_board_holder.add_child(_board)

	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.visible = false
	if _texture:
		var at := AtlasTexture.new()
		at.atlas = _texture
		at.region = _crop
		_preview.texture = at
	_board.add_child(_preview)

	# Botones inferiores
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 16)
	box.add_child(tools)

	var peek := Game.make_button("◎ Ver foto", 30)
	peek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	peek.button_down.connect(func(): _preview.visible = true)
	peek.button_up.connect(func(): _preview.visible = false)
	tools.add_child(peek)

	_numbers_btn = Game.make_button("# Números", 30)
	_numbers_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_numbers_btn.pressed.connect(_toggle_numbers)
	tools.add_child(_numbers_btn)

	var shuffle := Game.make_button("↻ Mezclar", 30)
	shuffle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shuffle.pressed.connect(_new_game)
	tools.add_child(shuffle)

	box.add_child(Game.make_label("Toca o desliza una pieza junto al hueco", 26))


func _layout_board() -> void:
	var avail := _board_holder.size
	var side := minf(avail.x, avail.y)
	_board.size = Vector2(side, side)
	_board.position = (avail - _board.size) / 2.0
	_board.pivot_offset = _board.size / 2.0
	for cell in board.size():
		var id := board[cell]
		if id >= 0:
			var t: Control = tiles[id]
			t.size = _cell_size()
			t.position = _cell_pos(cell)
	if tiles.has(n * n - 1):
		var last: Control = tiles[n * n - 1]
		last.size = _cell_size()
		last.position = _cell_pos(n * n - 1)
	_board.queue_redraw()


func _draw_board_bg() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.45)
	sb.set_corner_radius_all(18)
	_board.draw_style_box(sb, Rect2(Vector2.ZERO, _board.size))
	# Corazón en el hueco
	if playing and board.size() > 0:
		var c := _cell_pos(empty_cell) + _cell_size() / 2.0
		_board.draw_colored_polygon(Game.heart_points(c, _cell_size().x * 0.4), Color(1, 0.3, 0.43, 0.35))


func _cell_size() -> Vector2:
	return _board.size / float(n)


func _cell_pos(cell: int) -> Vector2:
	return Vector2(cell % n, cell / n) * _cell_size()


# ---------------------------------------------------------------- Partida

func _new_game() -> void:
	for t in tiles.values():
		t.queue_free()
	tiles.clear()
	if _win_layer:
		_win_layer.queue_free()
		_win_layer = null
	_bg.burst_mode = false

	board.clear()
	for i in n * n:
		board.append(i)
	# El hueco es la última pieza (abajo a la derecha)
	board[n * n - 1] = -1
	empty_cell = n * n - 1

	for id in n * n:
		var t := Tile.new()
		t.texture = _texture
		var piece := _crop.size / float(n)
		t.src_rect = Rect2(_crop.position + Vector2(id % n, id / n) * piece, piece)
		t.piece_id = id
		t.show_number = show_numbers
		_board.add_child(t)
		tiles[id] = t
	# La última pieza solo aparece al ganar
	tiles[n * n - 1].visible = false
	_board.move_child(_preview, -1)

	_shuffle()
	moves = 0
	elapsed = 0.0
	started = false
	playing = true
	_layout_board()
	_update_hud()


## Mezcla haciendo movimientos válidos al azar desde la solución,
## así el puzle siempre se puede resolver.
func _shuffle() -> void:
	var steps := n * n * 30
	var prev := -1
	var guard := 0
	while (steps > 0 or _is_solved()) and guard < 100000:
		guard += 1
		var options := _neighbors(empty_cell)
		options.erase(prev)
		var cell: int = options.pick_random()
		prev = empty_cell
		board[empty_cell] = board[cell]
		board[cell] = -1
		empty_cell = cell
		steps -= 1


func _neighbors(cell: int) -> Array[int]:
	var res: Array[int] = []
	var x := cell % n
	var y := cell / n
	if x > 0: res.append(cell - 1)
	if x < n - 1: res.append(cell + 1)
	if y > 0: res.append(cell - n)
	if y < n - 1: res.append(cell + n)
	return res


func _is_solved() -> bool:
	for i in n * n - 1:
		if board[i] != i:
			return false
	return true


## Intenta mover la pieza de `cell`. Si está en la misma fila o columna
## que el hueco, desliza toda la línea (como en los puzles reales).
func _try_move(cell: int) -> void:
	if not playing or cell == empty_cell or cell < 0 or cell >= n * n:
		return
	var cx := cell % n
	var cy := cell / n
	var ex := empty_cell % n
	var ey := empty_cell / n
	var step := 0
	if cy == ey:
		step = 1 if cx > ex else -1
	elif cx == ex:
		step = n if cy > ey else -n
	else:
		return
	# Mueve las piezas una a una desde el hueco hacia la pieza tocada
	while empty_cell != cell:
		var from := empty_cell + step
		var id := board[from]
		board[empty_cell] = id
		board[from] = -1
		_animate_tile(id, empty_cell)
		empty_cell = from
		moves += 1
	if not started:
		started = true
	_update_hud()
	_board.queue_redraw()
	if _is_solved():
		_win()


func _animate_tile(id: int, cell: int) -> void:
	var t: Control = tiles[id]
	_animating += 1
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(t, "position", _cell_pos(cell), SLIDE_TIME)
	tw.finished.connect(func(): _animating -= 1)


func _on_board_input(event: InputEvent) -> void:
	if not playing:
		return
	var pressed := false
	var released := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Solo si no se está emulando toque desde el ratón
		if ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
			return
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
	else:
		return

	if pressed:
		_press_pos = pos
		_pressing = true
	elif released and _pressing:
		_pressing = false
		var drag := pos - _press_pos
		if drag.length() >= SWIPE_THRESHOLD:
			# Deslizar: mueve la pieza vecina del hueco en esa dirección
			var ex := empty_cell % n
			var ey := empty_cell / n
			if absf(drag.x) > absf(drag.y):
				if drag.x > 0 and ex > 0: _try_move(empty_cell - 1)
				elif drag.x < 0 and ex < n - 1: _try_move(empty_cell + 1)
			else:
				if drag.y > 0 and ey > 0: _try_move(empty_cell - n)
				elif drag.y < 0 and ey < n - 1: _try_move(empty_cell + n)
		else:
			var cs := _cell_size()
			var cx := clampi(int(_press_pos.x / cs.x), 0, n - 1)
			var cy := clampi(int(_press_pos.y / cs.y), 0, n - 1)
			_try_move(cy * n + cx)


func _process(delta: float) -> void:
	if playing and started:
		elapsed += delta
		_time_label.text = "⏱ " + Game.format_time(elapsed)


func _update_hud() -> void:
	_moves_label.text = "♥ %d" % moves
	_time_label.text = "⏱ " + Game.format_time(elapsed)


func _toggle_numbers() -> void:
	show_numbers = not show_numbers
	_numbers_btn.modulate = Color(1, 1, 1, 1) if show_numbers else Color(1, 1, 1, 0.75)
	for t in tiles.values():
		t.show_number = show_numbers
		t.queue_redraw()


# ---------------------------------------------------------------- Victoria

func _win() -> void:
	playing = false
	var is_record := Game.register_win(moves, elapsed)
	_board.queue_redraw()

	await get_tree().create_timer(SLIDE_TIME + 0.05).timeout
	# Aparece la pieza que faltaba y desaparecen las separaciones
	var last: Control = tiles[n * n - 1]
	last.modulate.a = 0.0
	last.visible = true
	var tw := create_tween()
	tw.tween_property(last, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_method(_set_gap, 3.0, 0.0, 0.4)
	tw.tween_property(_board, "scale", Vector2(1.05, 1.05), 0.18)
	tw.tween_property(_board, "scale", Vector2.ONE, 0.18)
	_bg.burst_mode = true
	_bg.burst(60)
	await tw.finished
	await get_tree().create_timer(0.8).timeout
	_show_win_panel(is_record)


func _set_gap(value: float) -> void:
	for t in tiles.values():
		t.gap = value
		t.show_number = show_numbers and value > 0.5
		t.queue_redraw()


func _show_win_panel(is_record: bool) -> void:
	_win_layer = Control.new()
	_win_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_win_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.64, 0.07, 0.24, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_layer.add_child(dim)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.COLOR_WHITE
	sb.set_corner_radius_all(40)
	sb.set_content_margin_all(40)
	sb.shadow_color = Color(0.64, 0.07, 0.24, 0.4)
	sb.shadow_size = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_win_layer.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	v.add_child(Game.make_label("¡Lo conseguiste,\nDana!", 60, Game.COLOR_RED))
	v.add_child(Game.make_label("Te quiero ♥", 44))
	v.add_child(Game.make_label("%d movimientos · %s" % [moves, Game.format_time(elapsed)], 32))
	if is_record:
		v.add_child(Game.make_label("¡Nuevo récord!", 34, Game.COLOR_RED))

	var again := Game.make_button("↻ Otra vez", 38)
	again.pressed.connect(_new_game)
	v.add_child(again)
	var other := Game.make_button("♥ Otra foto", 38)
	other.pressed.connect(_go_back)
	v.add_child(other)

	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/photo_select.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
