extends Resource
class_name TeamStrategy
# Holds all the input the user/ai has generated to direct their team

var teamData: TeamData

enum SetterSystem {
	ONE_SETTER,
	TWO_SETTER,
	FIXED_POSITION_SETTER
}

const ONE_SETTER_REQUIREMENTS := {
	"setter": 1,
	"middle": 2,
	"outside": 2,
	"opposite": 1
}

const TWO_SETTER_REQUIREMENTS := {
	"setter": 2,
	"middle": 2,
	"outside": 1,
	"opposite": 1
}

const ROLE_ATTRIBUTE_WEIGHTS := {
	"setter": {
		"set": 1.9,
		"reception": 0.7,
		"serve": 0.6,
		"gameRead": 0.8,
		"speed": 0.3,
		"stamina": 0.2
	},
	"middle": {
		"block": 1.6,
		"spike": 1.0,
		"spikeHeight": 0.8,
		"blockHeight": 1.0,
		"serve": 0.3,
		"speed": 0.2
	},
	"outside": {
		"spike": 1.2,
		"reception": 1.3,
		"serve": 0.8,
		"block": 0.4,
		"gameRead": 0.6,
		"stamina": 0.3
	},
	"opposite": {
		"spike": 1.6,
		"serve": 0.8,
		"block": 0.9,
		"spikeHeight": 0.8,
		"blockHeight": 0.6,
		"reception": 0.2
	},
	"libero": {
		"reception": 1.8,
		"set": 0.6,
		"speed": 0.5,
		"gameRead": 0.8,
		"stamina": 0.4
	}
}

const SYSTEM_ROLE_WEIGHT_MULTIPLIERS := {
	SetterSystem.ONE_SETTER: {
		"setter": {"set": 1.1},
		"outside": {"reception": 1.05}
	},
	SetterSystem.TWO_SETTER: {
		"setter": {"set": 1.2, "reception": 1.05},
		"outside": {"spike": 1.1},
		"opposite": {"spike": 0.95}
	},
	SetterSystem.FIXED_POSITION_SETTER: {
		"setter": {"set": 1.15, "reception": 1.1}
	}
}

const ROLE_POOL_LIMITS := {
	"setter": 2,
	"middle": 3,
	"outside": 3,
	"opposite": 2
}

@export var preferred_setter_system: SetterSystem = SetterSystem.ONE_SETTER
@export_range(1, 6) var fixed_setter_position: int = 1

# Team style weights for whole-lineup evaluation.
@export var lineup_component_weights := {
	"offense": 1.0,
	"defense": 1.0,
	"serve_pressure": 1.0,
	"passing_stability": 1.0,
	"blocking": 1.0,
	"role_fit": 1.0,
	"role_mismatch_penalty": 1.0
}

@export var defaultReceiveRotations =  [
	[#setter in 1
		Vector3(5.5, 0, -4), # pos 1
		Vector3(5.0, 0, -2.8), # pos 2
		Vector3(3, 0, 1.3), # etc...
		Vector3(3.5, 0, 4),
		Vector3(5.3, 0, 2.6),
		Vector3(6.5, 0, 0)
	],
	[#setter in 6
		Vector3(5.5, 0, -1),
		Vector3(3.0, 0, -3.8),
		Vector3(.5, 0, -2.5),
		Vector3(3.5, 0, 4),
		Vector3(5, 0, 1),
		Vector3(1, 0, 0)
	],
	[#setter in 5
		Vector3(5.5, 0, -3.25),
		Vector3(2.75, 0, -3.0),
		Vector3(5, 0, 2.5),
		Vector3(.5, 0, 4),
		Vector3(1.5, 0, 1.3),
		Vector3(6.5, 0, 0)
	],
	[#setter 4
		Vector3(5.5, 0, -4),
		Vector3(5.0, 0, 2.5),
		Vector3(2.75, 0, 3.25),
		Vector3(.5, 0, 4),
		Vector3(6.5, 0, 0),
		Vector3(5, 0, -3.5)
	],
	[#setter 3
		Vector3(5.5, 0, -2.75),
		Vector3(2.75, 0, -1),
		Vector3(0.5, 0, 0),
		Vector3(4.5, 0, 2.5),
		Vector3(6.5, 0, 0),
		Vector3(7.5, 0, -1.75)
	],
	[#setter in 2
		Vector3(5.5, 0, -3),
		Vector3(.5, 0, 0),
		Vector3(5, 0, 2.75),
		Vector3(1.5, 0, 3.75),
		Vector3(7.75, 0, .6),
		Vector3(6.5, 0, 0)
	]
]

@export var teamLineupWeightProfile = TeamLineupWeightProfile.new()
@export var freeBallTarget:Vector3 = Vector3(4.5, 0, 0)
@export var preferredSettingWeights:Array
@export var preferredReceptionWeights:Array
@export var receiveRotations = {
	"default" : defaultReceiveRotations
}
@export var servingTargets:Array
@export var substitutionTirednessThresholds:Array

@export var setOptionWeights:Array

@export var scheduledSubstitutions:Array

# Blocking options
@export var maxCommitDistanceFromNet = 2

@export var playerToLiberoServe = []
@export var playerToLiberoReceive = []

# need to store each player, each of their strategies against each known opposition, and a default, and whether this overrides all others
@export var servingStrategies:Dictionary = {}

const SERVE_TARGET_BOUNDS := {
	"min_x": 0.65,
	"max_x": 4.35,
	"min_z": -4.1,
	"max_z": 4.1
}

const DEFAULT_SERVE_TARGET_WEIGHTS := {
	"target_weakest_receiver": 1.5,
	"target_libero": 0.8,
	"target_strongest_receiver": 0.35,
	"target_middle_attacker": 1.0,
	"target_deep_middle": 0.9,
	"target_short_zone": 0.6,
	"target_seam": 1.1
}

const DEFAULT_SERVE_TYPE_WEIGHTS := {
	"underarm": 0.15,
	"float": 1.0,
	"jump": 0.8
}

const DEFAULT_SERVE_AGGRESSION_WEIGHTS := {
	"safety": 0.45,
	"moderate": 1.0,
	"aggressive": 0.75
}

func _init(_teamData:TeamData = null) -> void:
	teamData = _teamData

func choose_starting_rotation() -> int:
	var best_rotation := 0
	var best_score := -INF

	for rotation in range(6):
		var score := score_rotation(rotation)
		if score > best_score:
			best_score = score
			best_rotation = rotation

	return best_rotation

func score_rotation(rotation:int) -> float:
	var six: Array[AthleteStats] = teamData.courtPlayers if not teamData.courtPlayers.is_empty() else teamData.matchPlayers.slice(0, 6)
	if six.size() < 6:
		return -INF

	var rotated: Array[AthleteStats] = []
	for i in range(6):
		rotated.append(six[(i + rotation) % 6])

	var score: float = 0.0

	if rotated[0].role == Enums.Role.Setter \
	or rotated[4].role == Enums.Role.Setter \
	or rotated[5].role == Enums.Role.Setter:
		score += 1.0

	for i in [0, 4, 5]:
		score += rotated[i].reception * 0.2

	for i in [1, 2, 3]:
		score += rotated[i].spike * 0.2

	return score

func select_starting_lineup(players: Array[AthleteStats]) -> Array[AthleteStats]:
	if players.size() < 6:
		return players.duplicate()

	var requirements: Dictionary = _system_role_requirements(preferred_setter_system)
	var role_keys: Array[String] = []
	for key in requirements.keys():
		role_keys.append(key)

	var pools: Dictionary = _build_role_pools(players, requirements)
	var assignments: Array = []
	_generate_assignments(role_keys, 0, requirements, pools, {}, {}, assignments)

	if assignments.is_empty():
		var fallback: Array[AthleteStats] = players.slice(0, 6)
		_assign_roles_from_system(fallback)
		return fallback

	var best_assignment = assignments[0]
	var best_score: float = -INF

	for assignment in assignments:
		var candidate_lineup: Array[AthleteStats] = _assignment_to_lineup(assignment, role_keys)
		if candidate_lineup.size() != 6:
			continue

		_apply_assignment_roles(assignment)
		candidate_lineup = _apply_system_position_rules(candidate_lineup)
		var candidate_score: float = _score_lineup(candidate_lineup, assignment)

		if candidate_score > best_score:
			best_score = candidate_score
			best_assignment = assignment

	_apply_assignment_roles(best_assignment)
	var best_lineup: Array[AthleteStats] = _assignment_to_lineup(best_assignment, role_keys)
	return _apply_system_position_rules(best_lineup)

func choose_passer(team_match_data: TeamMatchData = null, _rng: RandomNumberGenerator = null) -> AthleteStats:
	var players := _resolve_players(team_match_data)
	return _choose_player_by_skill(players, "reception", _rng)

func choose_setter(team_match_data: TeamMatchData = null, _rng: RandomNumberGenerator = null) -> AthleteStats:
	var players: Array[AthleteStats] = _resolve_players(team_match_data)
	if players.is_empty():
		return null

	if preferred_setter_system == SetterSystem.FIXED_POSITION_SETTER:
		var fixed_index: int = int(clamp(fixed_setter_position - 1, 0, players.size() - 1))
		return players[fixed_index]

	var setter_candidates: Array[AthleteStats] = []
	for player in players:
		if player.role == Enums.Role.Setter:
			setter_candidates.append(player)

	if setter_candidates.is_empty():
		setter_candidates = players

	return _choose_player_by_skill(setter_candidates, "set", _rng)

func choose_attacker(team_match_data: TeamMatchData = null, _rng: RandomNumberGenerator = null) -> AthleteStats:
	var players := _resolve_players(team_match_data)
	return _choose_player_by_skill(players, "spike", _rng)

func choose_blocker(team_match_data: TeamMatchData = null, _rng: RandomNumberGenerator = null) -> AthleteStats:
	var players := _resolve_players(team_match_data)
	return _choose_player_by_skill(players, "block", _rng)

func choose_serve_plan(server: AthleteStats, team_match_data: TeamMatchData = null, opponent_match_data: TeamMatchData = null, _rng: RandomNumberGenerator = null) -> Dictionary:
	if server == null:
		return {
			"target": Vector3(4.0, 0.0, 0.0),
			"serve_type": "float",
			"aggression": "moderate",
			"strategy": "target_deep_middle",
			"target_player_name": "",
			"target_player_reception": 0.0
		}

	var rng_to_use: RandomNumberGenerator = _rng if _rng != null else RandomNumberGenerator.new()
	if _rng == null:
		rng_to_use.randomize()

	var target_strategy: String = _weighted_string_choice(_serve_target_weights(), rng_to_use)
	var target_data: Dictionary = _resolve_serve_target(target_strategy, opponent_match_data, rng_to_use)
	var serve_type: String = _weighted_string_choice(_serve_type_weights_for_server(server), rng_to_use)
	var aggression: String = _weighted_string_choice(_serve_aggression_weights_for_server(server, serve_type), rng_to_use)

	return {
		"target": _clamp_serve_target(target_data.get("target", Vector3(4.0, 0.0, 0.0))),
		"serve_type": serve_type,
		"aggression": aggression,
		"strategy": target_strategy,
		"target_player_name": str(target_data.get("target_player_name", "")),
		"target_player_reception": float(target_data.get("target_player_reception", 0.0))
	}

func _resolve_players(team_match_data: TeamMatchData) -> Array[AthleteStats]:
	if team_match_data != null and not team_match_data.court_players.is_empty():
		return team_match_data.court_players
	return teamData.courtPlayers

func _serve_target_weights() -> Dictionary:
	var weights: Dictionary = DEFAULT_SERVE_TARGET_WEIGHTS.duplicate(true)
	var pressure: float = float(lineup_component_weights.get("serve_pressure", 1.0))

	if pressure >= 1.1:
		weights["target_weakest_receiver"] *= 1.2
		weights["target_seam"] *= 1.15
		weights["target_middle_attacker"] *= 1.15
	elif pressure <= 0.9:
		weights["target_libero"] *= 1.15
		weights["target_deep_middle"] *= 1.2
		weights["target_short_zone"] *= 1.15

	for key in weights.keys():
		if servingStrategies.has(key):
			weights[key] = float(servingStrategies[key])

	return weights

func _serve_type_weights_for_server(server: AthleteStats) -> Dictionary:
	var weights: Dictionary = DEFAULT_SERVE_TYPE_WEIGHTS.duplicate(true)
	var serve_skill: float = float(server.serve)

	if serve_skill >= 75.0:
		weights["jump"] *= 1.45
		weights["underarm"] *= 0.25
	elif serve_skill >= 55.0:
		weights["jump"] *= 1.15
		weights["float"] *= 1.1
		weights["underarm"] *= 0.45
	else:
		weights["underarm"] *= 1.45
		weights["jump"] *= 0.55

	var configured: Dictionary = servingStrategies.get("serve_types", {})
	for key in weights.keys():
		if configured.has(key):
			weights[key] = float(configured[key])

	return weights

func _serve_aggression_weights_for_server(server: AthleteStats, serve_type: String) -> Dictionary:
	var weights: Dictionary = DEFAULT_SERVE_AGGRESSION_WEIGHTS.duplicate(true)
	var serve_skill: float = float(server.serve)

	if serve_skill >= 75.0:
		weights["aggressive"] *= 1.35
		weights["safety"] *= 0.7
	elif serve_skill < 50.0:
		weights["safety"] *= 1.35
		weights["aggressive"] *= 0.6

	match serve_type:
		"jump":
			weights["aggressive"] *= 1.2
			weights["safety"] *= 0.75
		"underarm":
			weights["safety"] *= 1.4
			weights["aggressive"] *= 0.35
		"float":
			weights["moderate"] *= 1.1

	var configured: Dictionary = servingStrategies.get("aggression", {})
	for key in weights.keys():
		if configured.has(key):
			weights[key] = float(configured[key])

	return weights

func _resolve_serve_target(strategy: String, opponent_match_data: TeamMatchData, _rng: RandomNumberGenerator) -> Dictionary:
	var rng_to_use: RandomNumberGenerator = _rng if _rng != null else RandomNumberGenerator.new()
	if _rng == null:
		rng_to_use.randomize()

	if opponent_match_data == null:
		return {"target": Vector3(4.0, 0.0, 0.0)}

	var target_player: AthleteStats = null
	var target: Vector3 = Vector3(4.0, 0.0, 0.0)
	var receive_phase := "receive"
	var receive_side := 1.0

	match strategy:
		"target_libero":
			target_player = opponent_match_data.get_libero_on_court()
			if target_player == null:
				target_player = opponent_match_data.get_best_receiver()
		"target_strongest_receiver":
			target_player = opponent_match_data.get_best_receiver()
		"target_middle_attacker":
			target_player = opponent_match_data.get_best_middle_attacker()
		"target_seam":
			var candidates: Array[AthleteStats] = opponent_match_data.get_serve_receive_candidates()
			if candidates.size() >= 2:
				candidates.sort_custom(func(a, b): return a.reception > b.reception)
				var first_pos: Vector3 = opponent_match_data.get_phase_position_for_player(candidates[0], receive_phase, receive_side)
				var second_pos: Vector3 = opponent_match_data.get_phase_position_for_player(candidates[1], receive_phase, receive_side)
				target = (first_pos + second_pos) * 0.5
			else:
				target_player = opponent_match_data.get_worst_receiver()
		"target_short_zone":
			target = Vector3(rng_to_use.randf_range(1.2, 2.2), 0.0, rng_to_use.randf_range(-2.8, 2.8))
		"target_deep_middle":
			target = Vector3(rng_to_use.randf_range(3.7, 4.3), 0.0, rng_to_use.randf_range(-0.8, 0.8))
		_:
			target_player = opponent_match_data.get_worst_receiver()

	if target_player != null:
		target = opponent_match_data.get_phase_position_for_player(target_player, receive_phase, receive_side, target_player, false)
		target += Vector3(
			rng_to_use.randf_range(-0.35, 0.35),
			0.0,
			rng_to_use.randf_range(-0.45, 0.45)
		)

	return {
		"target": _clamp_serve_target(target),
		"target_player_name": _athlete_name(target_player),
		"target_player_reception": float(target_player.reception) if target_player != null else 0.0
	}

func _clamp_serve_target(target: Vector3) -> Vector3:
	return Vector3(
		clamp(target.x, float(SERVE_TARGET_BOUNDS["min_x"]), float(SERVE_TARGET_BOUNDS["max_x"])),
		0.0,
		clamp(target.z, float(SERVE_TARGET_BOUNDS["min_z"]), float(SERVE_TARGET_BOUNDS["max_z"]))
	)

func _weighted_string_choice(weights: Dictionary, _rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for value in weights.values():
		total += max(0.0, float(value))

	if total <= 0.0:
		for key in weights.keys():
			return str(key)
		return ""

	var roll: float = _rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for key in weights.keys():
		cumulative += max(0.0, float(weights[key]))
		if roll <= cumulative:
			return str(key)

	for key in weights.keys():
		return str(key)
	return ""

func _athlete_name(player: AthleteStats) -> String:
	if player == null:
		return ""
	return "%s %s" % [player.firstName, player.lastName]

func _choose_player_by_skill(players: Array[AthleteStats], skill_property: String, _rng: RandomNumberGenerator = null) -> AthleteStats:
	if players.is_empty():
		return null

	var chosen: AthleteStats = players[0]
	var best_score := -INF

	for player in players:
		var base_score: float = float(player.get(skill_property))
		var noise := 0.0
		if _rng != null:
			noise = _rng.randf_range(-10.0, 10.0)
		else:
			noise = randf_range(-10.0, 10.0)

		var sampled_score := base_score + noise
		if sampled_score > best_score:
			best_score = sampled_score
			chosen = player

	return chosen

func _system_role_requirements(system: SetterSystem) -> Dictionary:
	match system:
		SetterSystem.TWO_SETTER:
			return TWO_SETTER_REQUIREMENTS
		SetterSystem.FIXED_POSITION_SETTER:
			return ONE_SETTER_REQUIREMENTS
		_:
			return ONE_SETTER_REQUIREMENTS

func _build_role_pools(players: Array[AthleteStats], requirements: Dictionary) -> Dictionary:
	var pools: Dictionary = {}

	for role_key in requirements.keys():
		var scored: Array = []
		for player in players:
			var suitability: float = _score_player_for_role(player, role_key)
			scored.append({"player": player, "score": suitability})

		scored.sort_custom(func(a, b): return a["score"] > b["score"])

		var limit: int = int(ROLE_POOL_LIMITS.get(role_key, int(requirements[role_key]) + 1))
		limit = min(limit, scored.size())

		var pool: Array[AthleteStats] = []
		for i in range(limit):
			pool.append(scored[i]["player"])
		pools[role_key] = pool

	return pools

func _generate_assignments(
	role_keys: Array[String],
	role_index: int,
	requirements: Dictionary,
	pools: Dictionary,
	used_players: Dictionary,
	current_assignment: Dictionary,
	output: Array
) -> void:
	if role_index >= role_keys.size():
		output.append(current_assignment.duplicate(true))
		return

	var role_key: String = role_keys[role_index]
	var required_count: int = int(requirements[role_key])
	var pool = pools.get(role_key, [])
	var combos: Array = []
	_collect_combos(pool, required_count, 0, [], used_players, combos)

	for combo in combos:
		for player in combo:
			used_players[player] = true

		current_assignment[role_key] = combo
		_generate_assignments(role_keys, role_index + 1, requirements, pools, used_players, current_assignment, output)
		current_assignment.erase(role_key)

		for player in combo:
			used_players.erase(player)

func _collect_combos(
	pool: Array[AthleteStats],
	needed: int,
	start_index: int,
	picked: Array,
	used_players: Dictionary,
	output: Array
) -> void:
	if picked.size() == needed:
		output.append(picked.duplicate())
		return

	var remaining_needed: int = needed - picked.size()
	for i in range(start_index, pool.size()):
		if pool.size() - i < remaining_needed:
			break

		var player: AthleteStats = pool[i]
		if used_players.has(player):
			continue

		picked.append(player)
		_collect_combos(pool, needed, i + 1, picked, used_players, output)
		picked.pop_back()

func _assignment_to_lineup(assignment: Dictionary, role_keys: Array[String]) -> Array[AthleteStats]:
	var lineup: Array[AthleteStats] = []
	for role_key in role_keys:
		var role_players: Array = assignment.get(role_key, [])
		for player in role_players:
			lineup.append(player)
	return lineup

func _apply_assignment_roles(assignment: Dictionary) -> void:
	for role_key in assignment.keys():
		var players: Array = assignment[role_key]
		for player in players:
			player.role = _role_enum_for_key(role_key)

func _apply_system_position_rules(lineup: Array[AthleteStats]) -> Array[AthleteStats]:
	if preferred_setter_system != SetterSystem.FIXED_POSITION_SETTER:
		return lineup

	if lineup.is_empty():
		return lineup

	var target_index: int = int(clamp(fixed_setter_position - 1, 0, lineup.size() - 1))
	var setter_candidate: AthleteStats = _best_player_for_role(lineup, "setter")
	if setter_candidate == null:
		return lineup

	var setter_index := lineup.find(setter_candidate)
	if setter_index == -1:
		return lineup

	if setter_index != target_index:
		var temp: AthleteStats = lineup[target_index]
		lineup[target_index] = lineup[setter_index]
		lineup[setter_index] = temp

	lineup[target_index].role = Enums.Role.Setter
	return lineup

func _best_player_for_role(players: Array[AthleteStats], role_key: String) -> AthleteStats:
	if players.is_empty():
		return null

	var best: AthleteStats = players[0]
	var best_score: float = _score_player_for_role(best, role_key)
	for player in players:
		var score: float = _score_player_for_role(player, role_key)
		if score > best_score:
			best = player
			best_score = score
	return best

func _score_lineup(lineup: Array[AthleteStats], assignment: Dictionary) -> float:
	var offensive_score: float = 0.0
	var defensive_score: float = 0.0
	var serve_pressure_score: float = 0.0
	var passing_stability_score: float = 0.0
	var blocking_score: float = 0.0
	var role_fit_score: float = 0.0
	var mismatch_penalty: float = 0.0

	for player in lineup:
		offensive_score += player.spike + player.dump * 0.35
		defensive_score += player.reception * 0.7 + player.gameRead * 100.0 * 0.3
		serve_pressure_score += player.serve
		blocking_score += player.block + player.blockHeight * 100.0 * 0.4

	for role_key in assignment.keys():
		for player in assignment[role_key]:
			var fit: float = _score_player_for_role(player, role_key)
			role_fit_score += fit
			mismatch_penalty += max(0.0, 200.0 - fit)

	for player in lineup:
		if player.role == Enums.Role.Outside or player.role == Enums.Role.Libero or player.role == Enums.Role.Setter:
			passing_stability_score += player.reception

	var total_score: float = 0.0
	total_score += offensive_score * lineup_component_weights.get("offense", 1.0)
	total_score += defensive_score * lineup_component_weights.get("defense", 1.0)
	total_score += serve_pressure_score * lineup_component_weights.get("serve_pressure", 1.0)
	total_score += passing_stability_score * lineup_component_weights.get("passing_stability", 1.0)
	total_score += blocking_score * lineup_component_weights.get("blocking", 1.0)
	total_score += role_fit_score * lineup_component_weights.get("role_fit", 1.0)
	total_score -= mismatch_penalty * lineup_component_weights.get("role_mismatch_penalty", 1.0) * 0.05
	return total_score

func _score_player_for_role(player: AthleteStats, role_key: String) -> float:
	var weights: Dictionary = _weights_for_role(role_key)
	var score: float = 0.0
	for attribute_key in weights.keys():
		score += _attribute_value(player, attribute_key) * float(weights[attribute_key])
	return score

func _weights_for_role(role_key: String) -> Dictionary:
	var base = ROLE_ATTRIBUTE_WEIGHTS.get(role_key, {})
	var merged: Dictionary = base.duplicate(true)

	var system_overrides = SYSTEM_ROLE_WEIGHT_MULTIPLIERS.get(preferred_setter_system, {})
	var role_overrides = system_overrides.get(role_key, {})
	for attribute_key in role_overrides.keys():
		merged[attribute_key] = float(merged.get(attribute_key, 1.0)) * float(role_overrides[attribute_key])

	return merged

func _attribute_value(player: AthleteStats, attribute_key: String) -> float:
	match attribute_key:
		"serve":
			return player.serve
		"reception":
			return player.reception
		"set":
			return player.set
		"dump":
			return player.dump
		"spike":
			return player.spike
		"block":
			return player.block
		"stamina":
			return player.stamina * 100.0
		"speed":
			return player.speed * 10.0
		"height":
			return player.height * 100.0
		"verticalJump":
			return player.verticalJump * 100.0
		"spikeHeight":
			return player.spikeHeight * 100.0
		"blockHeight":
			return player.blockHeight * 100.0
		"gameRead":
			return player.gameRead * 100.0
		_:
			return 0.0

func _role_enum_for_key(role_key: String) -> Enums.Role:
	match role_key:
		"setter":
			return Enums.Role.Setter
		"middle":
			return Enums.Role.Middle
		"outside":
			return Enums.Role.Outside
		"opposite":
			return Enums.Role.Opposite
		"libero":
			return Enums.Role.Libero
		_:
			return Enums.Role.UNDEFINED

func _assign_roles_from_system(lineup: Array[AthleteStats]) -> void:
	if lineup.size() < 6:
		return

	var requirements: Dictionary = _system_role_requirements(preferred_setter_system)
	var taken: Dictionary = {}

	for role_key in ["setter", "middle", "outside", "opposite"]:
		var needed: int = int(requirements.get(role_key, 0))
		for _i in range(needed):
			var best := _best_available_for_role(lineup, role_key, taken)
			if best == null:
				continue
			taken[best] = true
			best.role = _role_enum_for_key(role_key)

func _best_available_for_role(lineup: Array[AthleteStats], role_key: String, taken: Dictionary) -> AthleteStats:
	var best: AthleteStats = null
	var best_score: float = -INF
	for player in lineup:
		if taken.has(player):
			continue
		var score: float = _score_player_for_role(player, role_key)
		if score > best_score:
			best = player
			best_score = score
	return best
