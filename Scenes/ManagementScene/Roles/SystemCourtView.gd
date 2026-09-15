extends Control
class_name SystemCourtView

func _draw() -> void:
	var area := Rect2(Vector2(18, 18), size - Vector2(36, 36))
	draw_rect(area, Color("195b3a"), true)
	draw_rect(area, Color("dcebe2"), false, 3.0)
	draw_line(area.position, Vector2(area.end.x, area.position.y), Color.WHITE, 5.0)
	draw_line(
		Vector2(area.position.x, area.position.y + area.size.y * 0.33),
		Vector2(area.end.x, area.position.y + area.size.y * 0.33),
		Color(1, 1, 1, 0.55),
		2.0
	)
	draw_string(ThemeDB.fallback_font, area.position + Vector2(10, 24), "NET", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
