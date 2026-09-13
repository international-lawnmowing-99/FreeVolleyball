extends Control
class_name CourtMiniMap

const COURT_LENGTH := 9.0
const COURT_WIDTH := 9.0
const PLAYER_CARD_SIZE := Vector2(82.0, 34.0)
const BALL_SIZE := Vector2(12.0, 12.0)
const TARGET_SIZE := Vector2(24.0, 24.0)
const TEAM_A_COLOR := Color(0.13, 0.72, 0.98, 1.0)
const TEAM_B_COLOR := Color(1.0, 0.42, 0.32, 1.0)
const LIBERO_COLOR := Color(0.95, 0.9, 0.25, 1.0)
const TARGET_COLOR := Color(1.0, 0.2, 0.72, 1.0)

@onready var title_label: Label = $Panel/Title
@onready var top_team_label: Label = $Panel/Court/TopTeamLabel
@onready var bottom_team_label: Label = $Panel/Court/BottomTeamLabel
@onready var player_cards: Array[Panel] = [
	$Panel/Court/TopPosition2, $Panel/Court/TopPosition3, $Panel/Court/TopPosition4,
	$Panel/Court/TopPosition1, $Panel/Court/TopPosition6, $Panel/Court/TopPosition5,
	$Panel/Court/BottomPosition1, $Panel/Court/BottomPosition6, $Panel/Court/BottomPosition5,
	$Panel/Court/BottomPosition2, $Panel/Court/BottomPosition3, $Panel/Court/BottomPosition4
]
@onready var goal_cards: Array[Panel] = [
	$Panel/Court/GoalCard1, $Panel/Court/GoalCard2, $Panel/Court/GoalCard3,
	$Panel/Court/GoalCard4, $Panel/Court/GoalCard5, $Panel/Court/GoalCard6,
	$Panel/Court/GoalCard7, $Panel/Court/GoalCard8, $Panel/Court/GoalCard9,
	$Panel/Court/GoalCard10, $Panel/Court/GoalCard11, $Panel/Court/GoalCard12
]
@onready var ball_marker: Panel = $Panel/Court/BallMarker
@onready var target_marker: Panel = $Panel/Court/TargetMarker

var phase_name := "No phase"
var teams: Array = []
var ball_state: Dictionary = {}
var target_position: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh_styles()
	refresh()

func set_snapshot(snapshot: Dictionary) -> void:
	phase_name = str(snapshot.get("phase", "No phase"))
	teams = snapshot.get("teams", []).duplicate(true)
	ball_state = snapshot.get("ball_state", {}).duplicate(true)
	target_position = snapshot.get("target_position", {}).duplicate(true)
	refresh()

func clear_snapshot() -> void:
	phase_name = "No phase"
	teams = []
	ball_state = {}
	target_position = {}
	refresh()

func refresh() -> void:
	if not is_node_ready():
		return
	title_label.text = "Court View: %s" % phase_name.capitalize()
	_update_team_headers()
	_update_players()
	_update_ball()
	_update_target()

func refresh_styles() -> void:
	_apply_style($Panel, Color(0.035, 0.055, 0.075, 0.96), Color(0.35, 0.42, 0.46, 0.8))
	_apply_style($Panel/Court, Color(0.08, 0.35, 0.2, 1.0), Color(0.75, 0.82, 0.86, 0.75))
	for card in player_cards:
		_apply_style(card, Color(0.04, 0.08, 0.12, 0.96), Color.WHITE)
	for card in goal_cards:
		_apply_style(card, Color(0.04, 0.08, 0.12, 0.16), Color.WHITE)
	_apply_style(ball_marker, Color(1.0, 0.86, 0.22, 1.0), Color(1.0, 1.0, 0.85, 1.0))
	_apply_style(target_marker, Color(TARGET_COLOR, 0.22), TARGET_COLOR)

func _update_team_headers() -> void:
	var top_name := ""
	var bottom_name := ""
	var top_color := TEAM_A_COLOR
	var bottom_color := TEAM_B_COLOR
	for team_data in teams:
		var team_name := str(team_data.get("team_name", "Team"))
		var team_color := _team_color(team_data)
		var players: Array = team_data.get("players", [])
		if players.is_empty():
			continue
		var average_x := 0.0
		for player_data in players:
			var player_position: Dictionary = player_data.get("position", {})
			average_x += float(player_position.get("x", 0.0))
		average_x /= players.size()
		if average_x >= 0.0:
			top_name = team_name
			top_color = team_color
		else:
			bottom_name = team_name
			bottom_color = team_color
	top_team_label.text = top_name if not top_name.is_empty() else "Team"
	bottom_team_label.text = bottom_name if not bottom_name.is_empty() else "Team"
	top_team_label.add_theme_color_override("font_color", top_color)
	bottom_team_label.add_theme_color_override("font_color", bottom_color)

func _update_players() -> void:
	var player_index := 0
	for team_data in teams:
		var team_color := _team_color(team_data)
		for player_data in team_data.get("players", []):
			if player_index >= player_cards.size():
				break
			_update_player_card(player_index, player_data, team_color)
			player_index += 1
	for index in range(player_index, player_cards.size()):
		player_cards[index].visible = false
		goal_cards[index].visible = false

func _update_player_card(index: int, player_data: Dictionary, team_color: Color) -> void:
	var card: Panel = player_cards[index]
	var goal_card: Panel = goal_cards[index]
	var card_size := _player_card_size()
	var current_position: Dictionary = player_data.get("position", {})
	var internal_state: Dictionary = player_data.get("internal_state", {})
	var movement: Dictionary = internal_state.get("movement", {})
	var rotation_position := int(internal_state.get("rotation_position", index + 1))
	var player_name := str(player_data.get("player_name", "Unknown"))
	var is_libero := _is_libero(player_data, internal_state)
	var label: Label = card.get_node("Label")
	var text_lines: Array[String] = [player_name, "R%d" % rotation_position]
	if is_libero:
		text_lines.append("LIBERO")
	label.text = "\n".join(text_lines)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", LIBERO_COLOR if is_libero else Color.WHITE)
	card.visible = true
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	card.size = card_size
	card.position = _court_to_canvas(current_position) - card_size * 0.5
	_apply_style(card, team_color.darkened(0.45), team_color)

	var goal_position: Dictionary = movement.get("goal_position", {})
	var has_goal := not movement.is_empty() and not goal_position.is_empty() and _distance_xz(current_position, goal_position) > 0.05
	goal_card.visible = has_goal
	if has_goal:
		goal_card.size = card_size
		goal_card.position = _court_to_canvas(goal_position) - card_size * 0.5
		_apply_style(goal_card, Color(team_color, 0.12), Color(team_color, 0.7))

func _player_card_size() -> Vector2:
	var court_size: Vector2 = $Panel/Court.size
	var scale_factor: float = minf(court_size.x / 360.0, court_size.y / 360.0)
	return PLAYER_CARD_SIZE * clampf(scale_factor, 0.65, 1.0)

func _update_ball() -> void:
	ball_marker.visible = not ball_state.is_empty()
	if not ball_marker.visible:
		return
	var ball_position: Dictionary = ball_state.get("position", {})
	ball_marker.size = BALL_SIZE
	ball_marker.position = _court_to_canvas(ball_position) - BALL_SIZE * 0.5

func _update_target() -> void:
	target_marker.visible = not target_position.is_empty()
	if not target_marker.visible:
		return
	target_marker.size = TARGET_SIZE
	target_marker.position = _court_to_canvas(target_position) - TARGET_SIZE * 0.5

func _court_to_canvas(position_data: Dictionary) -> Vector2:
	var court_size: Vector2 = $Panel/Court.size
	var world_x := float(position_data.get("x", 0.0))
	var world_z := float(position_data.get("z", 0.0))
	return Vector2(
		clamp((world_z + COURT_WIDTH * 0.5) / COURT_WIDTH, 0.0, 1.0) * court_size.x,
		clamp((COURT_LENGTH * 0.5 - world_x) / COURT_LENGTH, 0.0, 1.0) * court_size.y
	)

func _distance_xz(first: Dictionary, second: Dictionary) -> float:
	return Vector2(
		float(first.get("x", 0.0)) - float(second.get("x", 0.0)),
		float(first.get("z", 0.0)) - float(second.get("z", 0.0))
	).length()

func _apply_style(control: Control, fill_color: Color, border_color: Color) -> void:
	var style := control.get_theme_stylebox("panel")
	if style == null:
		style = StyleBoxFlat.new()
	var card_style := style.duplicate()
	card_style.bg_color = fill_color
	card_style.border_color = border_color
	control.add_theme_stylebox_override("panel", card_style)

func _is_libero(player_data: Dictionary, internal_state: Dictionary) -> bool:
	if str(internal_state.get("role_name", "")).to_lower() == "libero":
		return true
	return str(player_data.get("player_name", "")).findn("libero") != -1

func _team_color(team_data: Dictionary) -> Color:
	return TEAM_A_COLOR if str(team_data.get("team_slot", "")) == "a" else TEAM_B_COLOR
