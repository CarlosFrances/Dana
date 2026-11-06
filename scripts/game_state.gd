extends Node
## Estado global del juego (autoload "Game").
## Guarda la foto elegida, la dificultad y el progreso de Dana.

const PHOTOS_DIR := "res://assets/photos/"
const SAVE_PATH := "user://progreso.cfg"
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]

# Paleta de colores "amor"
const COLOR_BG_TOP := Color("#ffe3ea")
const COLOR_BG_BOTTOM := Color("#ffb3c6")
const COLOR_PINK := Color("#ff8fab")
const COLOR_RED := Color("#ff4d6d")
const COLOR_DARK := Color("#a4133c")
const COLOR_WHITE := Color("#fffafc")

## Tamaño del puzle (3 = 3x3, 4 = 4x4, 5 = 5x5)
var grid_size: int = 3
## Ruta de la foto seleccionada
var selected_photo: String = ""
## Mejor resultado por foto y tamaño: { "ruta|3": {"moves": int, "time": float} }
var best_scores: Dictionary = {}

var _photos_cache: PackedStringArray = []


func _ready() -> void:
	load_progress()


## Devuelve la lista de fotos disponibles en res://assets/photos/
## (funciona tanto en el editor como en el juego exportado al móvil).
func get_photos() -> PackedStringArray:
	if not _photos_cache.is_empty():
		return _photos_cache
	var found := {}
	var dir := DirAccess.open(PHOTOS_DIR)
	if dir == null:
		return _photos_cache
	for file_name in dir.get_files():
		# En el juego exportado los archivos aparecen como "foto.png.import" / ".remap"
		var clean := file_name.trim_suffix(".import").trim_suffix(".remap")
		if clean.get_extension().to_lower() in IMAGE_EXTENSIONS:
			found[PHOTOS_DIR + clean] = true
	var list: Array = found.keys()
	list.sort()
	_photos_cache = PackedStringArray(list)
	return _photos_cache


func load_photo(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func score_key(photo: String, size: int) -> String:
	return "%s|%d" % [photo.get_file(), size]


func is_completed(photo: String, size: int = -1) -> bool:
	if size > 0:
		return best_scores.has(score_key(photo, size))
	for s in [3, 4, 5]:
		if best_scores.has(score_key(photo, s)):
			return true
	return false


## Registra una victoria. Devuelve true si es un nuevo récord.
func register_win(moves: int, time: float) -> bool:
	var key := score_key(selected_photo, grid_size)
	var record: Dictionary = best_scores.get(key, {})
	var is_record := record.is_empty() or moves < int(record["moves"]) \
			or (moves == int(record["moves"]) and time < float(record["time"]))
	if is_record:
		best_scores[key] = {"moves": moves, "time": time}
		save_progress()
	return is_record


func get_best(photo: String, size: int) -> Dictionary:
	return best_scores.get(score_key(photo, size), {})


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ajustes", "grid_size", grid_size)
	cfg.set_value("progreso", "best_scores", best_scores)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	grid_size = int(cfg.get_value("ajustes", "grid_size", 3))
	best_scores = cfg.get_value("progreso", "best_scores", {})


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]


## Puntos de un corazón centrado en `center` con ancho aproximado `size`.
static func heart_points(center: Vector2, size: float, steps: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k := size / 34.0
	for i in steps:
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(center + Vector2(x, -y) * k)
	return pts


## Botón con estilo romántico (redondeado, rosa).
static func make_button(text: String, font_size: int = 40) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, font_size * 2.4)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", COLOR_WHITE)
	b.add_theme_color_override("font_hover_color", COLOR_WHITE)
	b.add_theme_color_override("font_pressed_color", COLOR_WHITE)
	b.add_theme_color_override("font_focus_color", COLOR_WHITE)
	b.add_theme_stylebox_override("normal", _box(COLOR_RED))
	b.add_theme_stylebox_override("hover", _box(COLOR_RED.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", _box(COLOR_DARK))
	b.add_theme_stylebox_override("focus", _box(COLOR_RED, true))
	b.add_theme_stylebox_override("disabled", _box(COLOR_PINK.lightened(0.3)))
	return b


static func _box(color: Color, focus: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(40)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0.64, 0.07, 0.24, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	if focus:
		sb.draw_center = false
		sb.border_color = COLOR_WHITE
		sb.set_border_width_all(4)
	return sb


static func make_label(text: String, font_size: int, color: Color = COLOR_DARK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", COLOR_WHITE)
	l.add_theme_constant_override("outline_size", max(4, font_size / 6))
	return l
