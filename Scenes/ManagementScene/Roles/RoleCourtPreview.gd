extends Control
class_name RoleCourtPreview

const Resolver = preload("res://_newhierarchy/simulation/team/roles/RolePreviewResolver.gd")

var preview_rotation := 1
var phase := "receive"
var roles: Array[PlayerRoleDefinition] = []
var tactical_system: RoleTacticalSystem

func configure(new_rotation: int, new_phase: String, new_roles: Array[PlayerRoleDefinition], new_system: RoleTacticalSystem = null) -> void:
	preview_rotation = new_rotation
	phase = new_phase
	roles = new_roles
	tactical_system = new_system
	queue_redraw()

func _draw() -> void:
	var area := Rect2(Vector2(10, 10), size - Vector2(20, 20))
	draw_rect(area, Color("195b3a"), true)
	draw_rect(area, Color("dcebe2"), false, 3.0)
	# The net is deliberately the top boundary: this is one team's half only.
	draw_line(area.position, Vector2(area.end.x, area.position.y), Color.WHITE, 5.0)
	draw_line(Vector2(area.position.x, area.position.y + area.size.y * 0.33), Vector2(area.end.x, area.position.y + area.size.y * 0.33), Color(1, 1, 1, .55), 1.0)
	var font := ThemeDB.fallback_font
	for player in Resolver.build_phase(preview_rotation, phase, roles, tactical_system):
		var start: Vector2 = _to_canvas(player.start, area)
		var target: Vector2 = _to_canvas(player.target, area)
		if start.distance_to(target) > 3.0:
			draw_line(start, target, Color("ffdc5d"), 2.0)
			draw_circle(target, 7.0, Color("ffdc5d"))
		draw_circle(start, 16.0, Color("163552"))
		draw_arc(start, 16.0, 0.0, TAU, 20, Color.WHITE, 1.5)
		draw_string(font, start + Vector2(-5, 5), str(player.physical_position), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		draw_string(font, start + Vector2(-34, 31), str(player.role_name).left(10), HORIZONTAL_ALIGNMENT_CENTER, 68, 11, Color.WHITE)
	draw_string(font, area.position + Vector2(8, 20), "NET  •  Rotation %d  •  %s" % [preview_rotation, phase.capitalize()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _to_canvas(position: Vector3, area: Rect2) -> Vector2:
	return Vector2(
		area.position.x + (position.z + 4.5) / 9.0 * area.size.x,
		area.position.y + clamp(position.x / 4.8, 0.0, 1.0) * area.size.y
	)
