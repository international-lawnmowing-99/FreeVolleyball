extends Control
class_name CourtLineupView

const HUMAN_COLOR := Color(0.13, 0.72, 0.98, 1.0)
const OPPONENT_COLOR := Color(1.0, 0.42, 0.32, 1.0)
const OCCUPIED_COLOR := Color(0.04, 0.08, 0.12, 0.94)
const EMPTY_COLOR := Color(0.1, 0.14, 0.17, 0.9)

@onready var top_team_label: Label = $TopTeamLabel
@onready var bottom_team_label: Label = $BottomTeamLabel
@onready var top_bench_label: Label = $TopBenchLabel
@onready var bottom_bench_label: Label = $BottomBenchLabel
@onready var top_bench: VBoxContainer = $TopBench
@onready var bottom_bench: VBoxContainer = $BottomBench

var human_team: TeamData
var opponent_team: TeamData
var top_position_labels: Dictionary = {}
var bottom_position_labels: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for position in range(1, 7):
		top_position_labels[position] = get_node("Court/TopPosition%d/Label" % position)
		bottom_position_labels[position] = get_node("Court/BottomPosition%d/Label" % position)
	refresh()

func set_teams(_human_team: TeamData, _opponent_team: TeamData) -> void:
	human_team = _human_team
	opponent_team = _opponent_team
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_node_ready():
		return
	_update_team_half(opponent_team, OPPONENT_COLOR, top_team_label, top_position_labels)
	_update_team_half(human_team, HUMAN_COLOR, bottom_team_label, bottom_position_labels)
	_update_bench(opponent_team, top_bench, top_bench_label, OPPONENT_COLOR)
	_update_bench(human_team, bottom_bench, bottom_bench_label, HUMAN_COLOR)

func _update_team_half(team: TeamData, team_color: Color, team_label: Label, labels: Dictionary) -> void:
	team_label.text = "Opponent" if team == null else team.teamName
	team_label.add_theme_color_override("font_color", team_color)
	var players_by_position := _players_by_position(team)
	for position in range(1, 7):
		var athlete: AthleteStats = players_by_position.get(position)
		var label: Label = labels[position]
		label.text = "Position %d\n%s" % [position, _athlete_name(athlete)]
		label.modulate = Color.WHITE if athlete != null else Color(1, 1, 1, 0.45)
		var card: Panel = label.get_parent()
		_set_card_color(card, team_color, athlete != null)

func _update_bench(team: TeamData, bench: VBoxContainer, bench_label: Label, team_color: Color) -> void:
	bench_label.add_theme_color_override("font_color", team_color)
	var bench_players: Array = [] if team == null else team.benchPlayers
	for index in range(bench.get_child_count()):
		var player_label: Label = bench.get_child(index)
		var occupied: bool = index < bench_players.size()
		player_label.text = _athlete_name(bench_players[index]) if occupied else "Empty"
		player_label.modulate = Color.WHITE if occupied else Color(1, 1, 1, 0.45)
		player_label.add_theme_color_override("font_color", team_color)
		_set_card_color(player_label, team_color, occupied)

func _set_card_color(control: Control, team_color: Color, occupied: bool) -> void:
	var style := control.get_theme_stylebox("panel")
	if style == null:
		style = control.get_theme_stylebox("normal")
	if style == null:
		return
	var card_style := style.duplicate()
	card_style.bg_color = OCCUPIED_COLOR if occupied else EMPTY_COLOR
	card_style.border_color = team_color if occupied else Color(0.75, 0.82, 0.86, 0.75)
	control.add_theme_stylebox_override("panel" if control is Panel else "normal", card_style)

func _players_by_position(team: TeamData) -> Dictionary:
	var players_by_position := {}
	if team == null:
		return players_by_position
	for athlete in team.courtPlayers:
		if athlete != null:
			players_by_position[int(athlete.rotationPosition)] = athlete
	return players_by_position

func _athlete_name(athlete: AthleteStats) -> String:
	if athlete == null:
		return "Empty"
	return "%s %s" % [athlete.firstName, athlete.lastName]
