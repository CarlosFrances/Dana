extends Control
## Una pieza del puzle: dibuja su trozo de la foto.

var texture: Texture2D
var src_rect: Rect2
var piece_id: int = 0
var show_number: bool = false
var gap: float = 3.0  ## Separación visual entre piezas (0 al ganar)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2(gap, gap), size - Vector2(gap, gap) * 2.0)
	if gap > 0.5:
		draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0.64, 0.07, 0.24, 0.35))
	if texture:
		draw_texture_rect_region(texture, r, src_rect)
	else:
		draw_rect(r, Game.COLOR_PINK)
	if gap > 0.5:
		draw_rect(r, Color(1, 1, 1, 0.85), false, 3.0)
	if show_number:
		var font := get_theme_default_font()
		var fs := int(size.y * 0.22)
		var txt := str(piece_id + 1)
		var badge_c := r.position + Vector2(fs * 0.9, fs * 0.9)
		draw_circle(badge_c, fs * 0.75, Color(1, 0.3, 0.43, 0.9))
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, badge_c + Vector2(-ts.x / 2.0, fs * 0.35), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
