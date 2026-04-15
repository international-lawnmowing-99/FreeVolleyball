extends Control
class_name CourtMiniMap

const COURT_LENGTH: float = 18.0
const COURT_WIDTH: float = 9.0
const THREE_METER_LINE_FROM_NET: float = 3.0
const COURT_LINE_COLOR := Color(0.92, 0.94, 0.96, 0.95)
const THREE_METER_COLOR := Color(0.92, 0.94, 0.96, 0.35)
const TEAM_COLORS := {
	"Alpha": Color(0.13, 0.72, 0.98, 1.0),
	"Bravo": Color(1.0, 0.42, 0.32, 1.0)
}
const TARGET_COLOR := Color(1.0, 1.0, 1.0, 0.28)
const ARROW_COLOR := Color(1.0, 1.0, 1.0, 0.22)

var phase_name: String = "No phase"
var teams: Array = []

func _ready() -> void:
	top_level = false
	z_index = 10
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func set_snapshot(snapshot: Dictionary) -> void:
	phase_name = str(snapshot.get("phase", "No phase"))
	teams = snapshot.get("teams", []).duplicate(true)
	queue_redraw()

func clear_snapshot() -> void:
	phase_name = "No phase"
	teams = []
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size).grow(-10.0)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	draw_rect(rect, Color(0.06, 0.35, 0.17, 0.88), true)
	_draw_court_lines(rect)
	_draw_phase_label(rect)

	for team_data in teams:
		_draw_team(team_data, rect)

	if teams.is_empty():
		_draw_empty_state(rect)

func _draw_court_lines(rect: Rect2) -> void:
	draw_rect(rect, COURT_LINE_COLOR, false, 2.0)
	var net_y := rect.position.y + rect.size.y * 0.5
	draw_line(Vector2(rect.position.x, net_y), Vector2(rect.end.x, net_y), COURT_LINE_COLOR, 2.0)

	var front_line_offset: float = rect.size.y * (THREE_METER_LINE_FROM_NET / COURT_LENGTH)
	draw_line(
		Vector2(rect.position.x, net_y - front_line_offset),
		Vector2(rect.end.x, net_y - front_line_offset),
		THREE_METER_COLOR,
		2.0
	)
	draw_line(
		Vector2(rect.position.x, net_y + front_line_offset),
		Vector2(rect.end.x, net_y + front_line_offset),
		THREE_METER_COLOR,
		2.0
	)

func _draw_phase_label(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, rect.position + Vector2(6, 18), "Court View: %s" % phase_name.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1, 1, 1, 0.88))

func _draw_empty_state(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var message := "Generate world and step the rally to populate the court map."
	var text_size := font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24.0, 14)
	var origin := Vector2(
		rect.position.x + rect.size.x * 0.5 - text_size.x * 0.5,
		rect.position.y + rect.size.y * 0.5
	)
	draw_multiline_string(font, origin, message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24.0, 14, -1, Color(1, 1, 1, 0.55))

func _draw_team(team_data: Dictionary, rect: Rect2) -> void:
	var team_name: String = str(team_data.get("team_name", "Team"))
	var players: Array = team_data.get("players", [])
	var team_color: Color = TEAM_COLORS.get(team_name, Color(0.95, 0.95, 0.95, 1.0))
	for player in players:
		_draw_player(player, rect, team_color)

func _draw_player(player: Dictionary, rect: Rect2, team_color: Color) -> void:
	var position_data: Dictionary = player.get("position", {})
	var player_point := _court_to_canvas(position_data, rect)
	var internal_state: Dictionary = player.get("internal_state", {})
	var movement: Dictionary = internal_state.get("movement", {})
	if not movement.is_empty():
		_draw_target_and_arrow(player_point, movement, rect)
	_draw_player_token(player_point, str(internal_state.get("rotation_position", "?")), team_color)

func _draw_target_and_arrow(player_point: Vector2, movement: Dictionary, rect: Rect2) -> void:
	var goal_position: Dictionary = movement.get("goal_position", {})
	if goal_position.is_empty():
		return
	var target_point := _court_to_canvas(goal_position, rect)
	if player_point.distance_to(target_point) < 3.0:
		return

	draw_line(player_point, target_point, ARROW_COLOR, 1.5)
	var arrow_dir := (player_point - target_point).normalized()
	var arrow_left := target_point + arrow_dir.rotated(0.45) * 8.0
	var arrow_right := target_point + arrow_dir.rotated(-0.45) * 8.0
	draw_line(target_point, arrow_left, ARROW_COLOR, 1.5)
	draw_line(target_point, arrow_right, ARROW_COLOR, 1.5)
	_draw_transparent_label(target_point, "[x]", TARGET_COLOR)

func _draw_player_token(point: Vector2, number_text: String, team_color: Color) -> void:
	_draw_transparent_label(point, "[%s]" % number_text, team_color)

func _draw_transparent_label(point: Vector2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size := 16
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var origin := point - Vector2(text_size.x * 0.5, -text_size.y * 0.3)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 2, Color(0, 0, 0, color.a * 0.8))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _court_to_canvas(position_data: Dictionary, rect: Rect2) -> Vector2:
	var world_x: float = float(position_data.get("x", 0.0))
	var world_z: float = float(position_data.get("z", 0.0))
	var normalized_x: float = clamp((world_z + COURT_WIDTH * 0.5) / COURT_WIDTH, 0.0, 1.0)
	var normalized_y: float = clamp((COURT_LENGTH * 0.5 - world_x) / COURT_LENGTH, 0.0, 1.0)
	return Vector2(
		rect.position.x + normalized_x * rect.size.x,
		rect.position.y + normalized_y * rect.size.y
	)
