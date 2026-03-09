extends Node2D

@onready var play_point_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/PlayPointButton
@onready var play_set_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/PlaySetButton
@onready var status_label: Label = $CanvasLayer/Control/VBoxContainer/StatusLabel

var sim: MatchSimulation

func _ready() -> void:
	var team_a := TeamData.new()
	team_a.teamName = "Alpha"
	team_a.Populate(PlayerChoiceState.new(), ["Cameron"], ["Borgas"])
	_prefix_generated_player_names(team_a)
	team_a.select_starting_lineup()

	var team_b := TeamData.new()
	team_b.teamName = "Bravo"
	team_b.Populate(PlayerChoiceState.new(), ["Tiglath-Pileser"], ["III"])
	_prefix_generated_player_names(team_b)
	team_b.select_starting_lineup()

	sim = MatchSimulation.new(team_a, team_b)

	play_point_button.pressed.connect(_on_play_point_button_pressed)
	play_set_button.pressed.connect(_on_play_set_button_pressed)
	_refresh_status_text("Ready")

func _on_play_point_button_pressed() -> void:
	var result := sim.play_point()
	if result["type"] == "match_over":
		_refresh_status_text("Match complete")
		return

	var score_event: Dictionary = result["score_event"]
	var summary := "Point played"
	if score_event["type"] == "set_over":
		summary = "Set over: %s" % score_event["winner"].teamName
	elif score_event["type"] == "match_over":
		summary = "Match over: %s" % score_event["winner"].teamName

	_refresh_status_text(summary)

func _on_play_set_button_pressed() -> void:
	var result := sim.play_set()
	if result["type"] == "match_over":
		_refresh_status_text("Match complete")
		return

	var ending_event: Dictionary = result["ending_event"]
	var summary := "Set %d completed (%d rallies)" % [result["set_number"], result["rallies_played"]]
	if ending_event["type"] == "match_over":
		summary = "Match over: %s" % ending_event["winner"].teamName
	elif ending_event["type"] == "set_over":
		summary = "Set %d over: %s" % [result["set_number"], ending_event["winner"].teamName]

	_refresh_status_text(summary)

func _refresh_status_text(prefix: String) -> void:
	var sets_a: int = int(sim.score.sets_won[sim.team_a])
	var sets_b: int = int(sim.score.sets_won[sim.team_b])
	var points_a: int = int(sim.score.points[sim.team_a])
	var points_b: int = int(sim.score.points[sim.team_b])
	var serving_team_name: String = "N/A"
	var server_name: String = "N/A"
	if sim.serving_team != null:
		serving_team_name = sim.serving_team.teamName
		var server: AthleteStats = sim.get_current_server()
		if server != null:
			server_name = "%s %s" % [server.firstName, server.lastName]

	status_label.text = "%s\nSets %s %d - %s %d\nPoints %s %d - %s %d\nServing: %s\nServer: %s\nRallies: %d" % [
		prefix,
		sim.team_a.teamName, sets_a, sim.team_b.teamName, sets_b,
		sim.team_a.teamName, points_a, sim.team_b.teamName, points_b,
		serving_team_name, server_name,
		sim.rally_number
	]

func _prefix_generated_player_names(team: TeamData) -> void:
	for i in range(team.matchPlayers.size()):
		var athlete: AthleteStats = team.matchPlayers[i]
		athlete.firstName = "[%d] %s" % [i + 1, athlete.firstName]
