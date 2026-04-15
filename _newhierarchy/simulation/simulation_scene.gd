extends Node2D

@export_enum("Basic", "Intermediate", "Verbose") var demo_log_verbosity: int = 1

const TeamStrategyScript = preload("res://_newhierarchy/simulation/team/strategy/TeamStrategy.gd")

@onready var generate_world_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/GenerateWorldButton
@onready var play_point_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/PlayPointButton
@onready var play_set_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/PlaySetButton
@onready var next_rally_step_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/NextRallyStepButton
@onready var replay_last_point_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/ReplayLastPointButton
@onready var next_replay_frame_button: Button = $CanvasLayer/Control/VBoxContainer/Buttons/NextReplayFrameButton
@onready var status_label: Label = $CanvasLayer/Control/VBoxContainer/StatusLabel
@onready var rally_step_label: Label = $CanvasLayer/Control/VBoxContainer/RallyStepLabel
@onready var replay_label: Label = $CanvasLayer/Control/VBoxContainer/ReplayLabel
@onready var strategy_panel: PanelContainer = $CanvasLayer/Control/StrategyPanel
@onready var strategy_summary_label: Label = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/StrategySummaryLabel
@onready var setter_system_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/SetterSystemRow/SetterSystemOption
@onready var fixed_setter_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/FixedSetterRow/FixedSetterOption
@onready var set_distribution_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/SetDistributionRow/SetDistributionOption
@onready var front_court_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/FrontCourtRow/FrontCourtOption
@onready var middle_set_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/MiddleSetRow/MiddleSetOption
@onready var outside_set_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/OutsideSetRow/OutsideSetOption
@onready var scouting_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/ScoutingRow/ScoutingOption
@onready var block_commit_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/BlockCommitRow/BlockCommitOption
@onready var backcourt_shift_option: OptionButton = $CanvasLayer/Control/StrategyPanel/MarginContainer/StrategyVBox/BackcourtShiftRow/BackcourtShiftOption

var sim: MatchSimulation
var director: SimulationDirector
var workflow_log: SimulationEventLog
var simulation_world: SimulationWorldState
var active_replay: Dictionary = {}
var active_replay_frames: Array = []
var replay_frame_index: int = -1
var strategy_option_maps := {}

func _ready() -> void:
	workflow_log = SimulationEventLog.new()
	workflow_log.configure(demo_log_verbosity)
	director = SimulationDirector.new(workflow_log)

	generate_world_button.pressed.connect(_on_generate_world_button_pressed)
	play_point_button.pressed.connect(_on_play_point_button_pressed)
	play_set_button.pressed.connect(_on_play_set_button_pressed)
	next_rally_step_button.pressed.connect(_on_next_rally_step_button_pressed)
	replay_last_point_button.pressed.connect(_on_replay_last_point_button_pressed)
	next_replay_frame_button.pressed.connect(_on_next_replay_frame_button_pressed)
	_setup_strategy_ui()
	_set_match_buttons_enabled(false)
	_refresh_status_text("Ready to generate world")
	_refresh_rally_step_text("No rally steps yet")
	_refresh_replay_text("No replay loaded")
	_refresh_strategy_ui()

func _on_generate_world_button_pressed() -> void:
	simulation_world = SimulationWorldState.new()
	director.generate_game_world(simulation_world)

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

	sim = MatchSimulation.new(team_a, team_b, -1, workflow_log)
	_set_match_buttons_enabled(true)
	_refresh_status_text("Game world generated")
	_refresh_rally_step_text("No rally steps yet")
	_clear_active_replay("No replay loaded")
	_refresh_strategy_ui()

func _on_play_point_button_pressed() -> void:
	if sim == null:
		_refresh_status_text("Generate world first")
		return
	_refresh_rally_step_text("Rally step output cleared")
	var result := sim.play_point()
	if result["type"] == "match_over":
		_refresh_status_text("Match complete")
		return
	_load_replay(result.get("replay", {}))

	var score_event: Dictionary = result["score_event"]
	var summary := "Point played"
	if score_event["type"] == "set_over":
		summary = "Set over: %s" % score_event["winner"].teamName
	elif score_event["type"] == "match_over":
		summary = "Match over: %s" % score_event["winner"].teamName

	_refresh_status_text(summary)

func _on_play_set_button_pressed() -> void:
	if sim == null:
		_refresh_status_text("Generate world first")
		return
	_refresh_rally_step_text("Rally step output cleared")
	var result := sim.play_set()
	if result["type"] == "match_over":
		_refresh_status_text("Match complete")
		return
	if not sim.rally_replays.is_empty():
		_load_replay(sim.rally_replays[sim.rally_replays.size() - 1].get("replay", {}))

	var ending_event: Dictionary = result["ending_event"]
	var summary := "Set %d completed (%d rallies)" % [result["set_number"], result["rallies_played"]]
	if ending_event["type"] == "match_over":
		summary = "Match over: %s" % ending_event["winner"].teamName
	elif ending_event["type"] == "set_over":
		summary = "Set %d over: %s" % [result["set_number"], ending_event["winner"].teamName]

	_refresh_status_text(summary)

func _on_next_rally_step_button_pressed() -> void:
	if sim == null:
		_refresh_status_text("Generate world first")
		_refresh_rally_step_text("No rally steps yet")
		return

	var result := sim.next_rally_step()
	_refresh_rally_step_text(result.get("message", ""))

	if result["type"] == "match_over":
		_refresh_status_text("Match complete")
		return

	if result.get("rally_committed", false):
		var point_result: Dictionary = result["point_result"]
		_load_replay(point_result.get("replay", {}))
		var score_event: Dictionary = point_result["score_event"]
		var summary := "Rally step complete"
		if score_event["type"] == "set_over":
			summary = "Set over: %s" % score_event["winner"].teamName
		elif score_event["type"] == "match_over":
			summary = "Match over: %s" % score_event["winner"].teamName
		else:
			summary = "Point played"
		_refresh_status_text(summary)
		return

	_refresh_status_text("Rally %d in progress" % sim.rally_number)

func _on_replay_last_point_button_pressed() -> void:
	if sim == null or sim.rally_replays.is_empty():
		_refresh_replay_text("No completed point replay available")
		return
	_load_replay(sim.rally_replays[sim.rally_replays.size() - 1].get("replay", {}))
	_show_next_replay_frame()

func _on_next_replay_frame_button_pressed() -> void:
	_show_next_replay_frame()

func _refresh_status_text(prefix: String) -> void:
	if sim == null:
		var world_state := "not generated"
		if simulation_world != null:
			world_state = "generated"
		status_label.text = "%s\nNo active match\nWorld: %s" % [prefix, world_state]
		return


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

func _set_match_buttons_enabled(enabled: bool) -> void:
	play_point_button.disabled = not enabled
	play_set_button.disabled = not enabled
	next_rally_step_button.disabled = not enabled
	replay_last_point_button.disabled = not enabled
	next_replay_frame_button.disabled = not enabled
	strategy_panel.modulate = Color(1, 1, 1, 1.0 if enabled else 0.72)

func _refresh_rally_step_text(message: String) -> void:
	rally_step_label.text = "Rally Step Output:\n%s" % message

func _refresh_replay_text(message: String) -> void:
	replay_label.text = "Replay Output:\n%s" % message

func _clear_active_replay(message: String) -> void:
	active_replay = {}
	active_replay_frames = []
	replay_frame_index = -1
	_refresh_replay_text(message)

func _load_replay(replay: Dictionary) -> void:
	if replay.is_empty():
		_clear_active_replay("Replay missing")
		return

	active_replay = replay.duplicate(true)
	active_replay_frames = active_replay.get("frames", [])
	replay_frame_index = -1
	var summary: Dictionary = active_replay.get("summary", {})
	_refresh_replay_text(
		"Loaded replay for rally %s (%d frames, %d keyframes)"
		% [
			str(summary.get("rally_number", "?")),
			active_replay_frames.size(),
			int(summary.get("keyframe_count", 0))
		]
	)

func _show_next_replay_frame() -> void:
	if active_replay_frames.is_empty():
		_refresh_replay_text("No replay frames loaded")
		return

	replay_frame_index += 1
	if replay_frame_index >= active_replay_frames.size():
		replay_frame_index = 0

	var frame: Dictionary = active_replay_frames[replay_frame_index]
	_refresh_replay_text(_describe_replay_frame(frame))

func _describe_replay_frame(frame: Dictionary) -> String:
	var ball: Dictionary = frame.get("ball", {})
	var ball_position: Dictionary = ball.get("position", {})
	var focus: Dictionary = frame.get("focus", {})
	var lines: Array[String] = []
	lines.append(
		"Frame %d | t=%.2fs | phase=%s | action=%s | result=%s"
		% [
			replay_frame_index,
			float(frame.get("timestamp", 0.0)),
			str(frame.get("phase", "")),
			str(focus.get("action", "")),
			str(focus.get("result", ""))
		]
	)
	lines.append(
		"Ball pos=(%.2f, %.2f, %.2f)"
		% [
			float(ball_position.get("x", 0.0)),
			float(ball_position.get("y", 0.0)),
			float(ball_position.get("z", 0.0))
		]
	)

	var teams: Array = frame.get("teams", [])
	for team_data in teams:
		lines.append(_describe_replay_team(team_data))

	if frame.get("is_keyframe", false):
		lines.append("Keyframe")
	if not frame.get("stub_flags", []).is_empty():
		lines.append("Stub data: %s" % _join_variant_list(frame.get("stub_flags", [])))

	return "\n".join(lines)

func _describe_replay_team(team_data: Dictionary) -> String:
	var players: Array = team_data.get("players", [])
	if players.is_empty():
		return "%s: no player data" % str(team_data.get("team_name", "Team"))

	var snippets: Array[String] = []
	for i in range(min(players.size(), 2)):
		var player: Dictionary = players[i]
		var position: Dictionary = player.get("position", {})
		var animation: Dictionary = player.get("animation", {})
		snippets.append(
			"%s @ (%.1f, %.1f, %.1f) -> %s"
			% [
				str(player.get("player_name", "")),
				float(position.get("x", 0.0)),
				float(position.get("y", 0.0)),
				float(position.get("z", 0.0)),
				str(animation.get("name", ""))
			]
		)

	return "%s: %s" % [str(team_data.get("team_name", "Team")), " | ".join(snippets)]

func _join_variant_list(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)

func _setup_strategy_ui() -> void:
	strategy_option_maps["setter_system"] = _fill_option_button(
		setter_system_option,
		[
			{"label": "One Setter", "value": TeamStrategyScript.SetterSystem.ONE_SETTER},
			{"label": "Two Setter", "value": TeamStrategyScript.SetterSystem.TWO_SETTER},
			{"label": "Fixed Position", "value": TeamStrategyScript.SetterSystem.FIXED_POSITION_SETTER}
		]
	)
	strategy_option_maps["fixed_setter"] = _fill_option_button(
		fixed_setter_option,
		[
			{"label": "Position 1", "value": 1},
			{"label": "Position 2", "value": 2},
			{"label": "Position 3", "value": 3},
			{"label": "Position 4", "value": 4},
			{"label": "Position 5", "value": 5},
			{"label": "Position 6", "value": 6}
		]
	)
	strategy_option_maps["set_distribution"] = _fill_option_button(
		set_distribution_option,
		[
			{"label": "Balanced", "value": 0.55},
			{"label": "Best Hitter", "value": 0.8},
			{"label": "Spread Offence", "value": 0.3}
		]
	)
	strategy_option_maps["front_court"] = _fill_option_button(
		front_court_option,
		[
			{"label": "Balanced", "value": 1.0},
			{"label": "Front Heavy", "value": 1.35},
			{"label": "Backcourt Friendly", "value": 0.7}
		]
	)
	strategy_option_maps["middle"] = _fill_option_button(
		middle_set_option,
		[
			{"label": "Balanced", "value": 1.0},
			{"label": "Feature Middle", "value": 1.4},
			{"label": "De-emphasize", "value": 0.7}
		]
	)
	strategy_option_maps["outside"] = _fill_option_button(
		outside_set_option,
		[
			{"label": "Balanced", "value": 1.0},
			{"label": "Lean Outside", "value": 1.35},
			{"label": "Reduce Pins", "value": 0.75}
		]
	)
	strategy_option_maps["scouting"] = _fill_option_button(
		scouting_option,
		[
			{"label": "Low", "value": 0.15},
			{"label": "Medium", "value": 0.35},
			{"label": "High", "value": 0.65}
		]
	)
	strategy_option_maps["block_commit"] = _fill_option_button(
		block_commit_option,
		[
			{"label": "Soft Read", "value": 0.7},
			{"label": "Balanced", "value": 1.0},
			{"label": "Hard Commit", "value": 1.35}
		]
	)
	strategy_option_maps["backcourt_shift"] = _fill_option_button(
		backcourt_shift_option,
		[
			{"label": "Hold Base", "value": 0.7},
			{"label": "Balanced", "value": 1.0},
			{"label": "Aggressive Shift", "value": 1.35}
		]
	)

	setter_system_option.item_selected.connect(_on_setter_system_selected)
	fixed_setter_option.item_selected.connect(_on_fixed_setter_selected)
	set_distribution_option.item_selected.connect(_on_set_distribution_selected)
	front_court_option.item_selected.connect(_on_front_court_selected)
	middle_set_option.item_selected.connect(_on_middle_set_selected)
	outside_set_option.item_selected.connect(_on_outside_set_selected)
	scouting_option.item_selected.connect(_on_scouting_selected)
	block_commit_option.item_selected.connect(_on_block_commit_selected)
	backcourt_shift_option.item_selected.connect(_on_backcourt_shift_selected)

func _fill_option_button(button: OptionButton, entries: Array) -> Array:
	button.clear()
	for entry in entries:
		button.add_item(str(entry["label"]))
	return entries

func _refresh_strategy_ui() -> void:
	var strategy = _alpha_strategy()
	var has_strategy: bool = strategy != null
	setter_system_option.disabled = not has_strategy
	fixed_setter_option.disabled = not has_strategy
	set_distribution_option.disabled = not has_strategy
	front_court_option.disabled = not has_strategy
	middle_set_option.disabled = not has_strategy
	outside_set_option.disabled = not has_strategy
	scouting_option.disabled = not has_strategy
	block_commit_option.disabled = not has_strategy
	backcourt_shift_option.disabled = not has_strategy

	if not has_strategy:
		strategy_summary_label.text = "Generate world to inspect Team Alpha's strategy."
		return

	_select_option_for_value(setter_system_option, strategy_option_maps["setter_system"], strategy.preferred_setter_system)
	_select_option_for_value(fixed_setter_option, strategy_option_maps["fixed_setter"], strategy.fixed_setter_position)
	_select_option_for_value(set_distribution_option, strategy_option_maps["set_distribution"], strategy.set_distribution_preference)
	_select_option_for_value(front_court_option, strategy_option_maps["front_court"], strategy.prefer_front_court_sets)
	_select_option_for_value(middle_set_option, strategy_option_maps["middle"], strategy.prefer_middle_sets)
	_select_option_for_value(outside_set_option, strategy_option_maps["outside"], strategy.prefer_outside_sets)
	_select_option_for_value(scouting_option, strategy_option_maps["scouting"], strategy.opponent_setter_scouting_budget)
	_select_option_for_value(block_commit_option, strategy_option_maps["block_commit"], strategy.block_commit_tendency)
	_select_option_for_value(backcourt_shift_option, strategy_option_maps["backcourt_shift"], strategy.backcourt_shift_tendency)
	fixed_setter_option.disabled = strategy.preferred_setter_system != TeamStrategyScript.SetterSystem.FIXED_POSITION_SETTER

	strategy_summary_label.text = _describe_alpha_strategy(strategy)

func _select_option_for_value(button: OptionButton, entries: Array, value: Variant) -> void:
	var best_index: int = 0
	var best_delta: float = INF
	for i in range(entries.size()):
		var entry_value: Variant = entries[i]["value"]
		if typeof(entry_value) == TYPE_INT and typeof(value) == TYPE_INT:
			if int(entry_value) == int(value):
				best_index = i
				best_delta = 0.0
				break
		else:
			var delta = abs(float(entry_value) - float(value))
			if delta < best_delta:
				best_delta = delta
				best_index = i
	button.select(best_index)

func _alpha_strategy():
	if sim == null or sim.team_a == null:
		return null
	return sim.team_a.teamStrategy

func _describe_alpha_strategy(strategy) -> String:
	var setter_system_name := "One Setter"
	match strategy.preferred_setter_system:
		TeamStrategyScript.SetterSystem.TWO_SETTER:
			setter_system_name = "Two Setter"
		TeamStrategyScript.SetterSystem.FIXED_POSITION_SETTER:
			setter_system_name = "Fixed Position"

	var lines: Array[String] = []
	lines.append("System: %s" % setter_system_name)
	if strategy.preferred_setter_system == TeamStrategyScript.SetterSystem.FIXED_POSITION_SETTER:
		lines.append("Fixed setter in rotation %d" % strategy.fixed_setter_position)
	lines.append("Set distribution %.2f | front %.2f | middle %.2f | outside %.2f" % [
		strategy.set_distribution_preference,
		strategy.prefer_front_court_sets,
		strategy.prefer_middle_sets,
		strategy.prefer_outside_sets
	])
	lines.append("Scout %.2f | block commit %.2f | backcourt shift %.2f" % [
		strategy.opponent_setter_scouting_budget,
		strategy.block_commit_tendency,
		strategy.backcourt_shift_tendency
	])
	return "\n".join(lines)

func _entry_value(entries: Array, index: int, fallback: Variant) -> Variant:
	if index < 0 or index >= entries.size():
		return fallback
	return entries[index]["value"]

func _on_setter_system_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.preferred_setter_system = int(_entry_value(strategy_option_maps["setter_system"], index, strategy.preferred_setter_system))
	_refresh_strategy_ui()

func _on_fixed_setter_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.fixed_setter_position = int(_entry_value(strategy_option_maps["fixed_setter"], index, strategy.fixed_setter_position))
	_refresh_strategy_ui()

func _on_set_distribution_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.set_distribution_preference = float(_entry_value(strategy_option_maps["set_distribution"], index, strategy.set_distribution_preference))
	_refresh_strategy_ui()

func _on_front_court_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	var value := float(_entry_value(strategy_option_maps["front_court"], index, strategy.prefer_front_court_sets))
	strategy.prefer_front_court_sets = value
	strategy.prefer_back_court_sets = clamp(2.0 - value, 0.2, 2.5)
	_refresh_strategy_ui()

func _on_middle_set_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.prefer_middle_sets = float(_entry_value(strategy_option_maps["middle"], index, strategy.prefer_middle_sets))
	_refresh_strategy_ui()

func _on_outside_set_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.prefer_outside_sets = float(_entry_value(strategy_option_maps["outside"], index, strategy.prefer_outside_sets))
	_refresh_strategy_ui()

func _on_scouting_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.opponent_setter_scouting_budget = float(_entry_value(strategy_option_maps["scouting"], index, strategy.opponent_setter_scouting_budget))
	_refresh_strategy_ui()

func _on_block_commit_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.block_commit_tendency = float(_entry_value(strategy_option_maps["block_commit"], index, strategy.block_commit_tendency))
	_refresh_strategy_ui()

func _on_backcourt_shift_selected(index: int) -> void:
	var strategy = _alpha_strategy()
	if strategy == null:
		return
	strategy.backcourt_shift_tendency = float(_entry_value(strategy_option_maps["backcourt_shift"], index, strategy.backcourt_shift_tendency))
	_refresh_strategy_ui()

func _prefix_generated_player_names(team: TeamData) -> void:
	for i in range(team.matchPlayers.size()):
		var athlete: AthleteStats = team.matchPlayers[i]
		athlete.firstName = "[%d] %s" % [i + 1, athlete.firstName]
