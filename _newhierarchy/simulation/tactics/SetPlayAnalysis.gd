extends RefCounted

class_name SetPlayAnalysis

const GRAVITY: float = 9.8
const MAX_SET_VELOCITY: float = 10.0
const MIN_BINARY_SEARCH_SPEED: float = 0.1
const BINARY_SEARCH_STEPS: int = 18
const PERFECT_PASS_SETTER_X: float = 0.5

static func evaluate_attacking_options(
	set_origin: Vector3,
	team_side: float,
	team_match_data: TeamMatchData,
	setter: AthleteStats,
	team_strategy: TeamStrategy
) -> Array[Dictionary]:
	var candidates := _eligible_attackers(team_match_data, setter)
	var options: Array[Dictionary] = []
	var strongest_spike: float = 1.0

	for attacker in candidates:
		strongest_spike = max(strongest_spike, float(attacker.spike))

	for attacker in candidates:
		var contact_position := _attack_contact_position(team_match_data, attacker, team_side)
		var trajectory := _minimum_speed_trajectory(set_origin, contact_position)
		if trajectory.is_empty():
			continue

		var velocity: Vector3 = trajectory["velocity"]
		var flight_time: float = _time_till_ball_at_position(set_origin, velocity, contact_position)
		var difficulty: float = _set_difficulty(
			set_origin,
			contact_position,
			flight_time,
			attacker,
			team_side,
			max(float(setter.jumpSetHeight), 2.4)
		)
		var tendency_weight: float = 1.0
		if team_strategy != null:
			tendency_weight = team_strategy.setting_preference_weight_for_attacker(attacker)

		options.append({
			"attacker": attacker,
			"attacker_name": _athlete_name(attacker),
			"contact_position": contact_position,
			"set_velocity": velocity,
			"set_speed": velocity.length(),
			"set_time": flight_time,
			"set_difficulty": difficulty,
			"role_bucket": _role_bucket(attacker),
			"court_bucket": _court_bucket(attacker),
			"attack_lane": _attack_lane(attacker, contact_position),
			"tendency_weight": tendency_weight,
			"spike_skill": float(attacker.spike),
			"spike_skill_ratio": float(clamp(attacker.spike / strongest_spike, 0.35, 1.15))
		})

	return options

static func choose_attacking_option(options: Array[Dictionary], team_strategy: TeamStrategy, rng: RandomNumberGenerator) -> Dictionary:
	if options.is_empty():
		return {}

	var preference_for_best: float = 0.55
	if team_strategy != null:
		preference_for_best = team_strategy.set_distribution_preference

	var weighted_options: Array[Dictionary] = []
	for option in options:
		var tendency_weight: float = float(option.get("tendency_weight", 1.0))
		var skill_ratio: float = float(option.get("spike_skill_ratio", 1.0))
		var difficulty: float = float(option.get("set_difficulty", 0.5))
		var hitter_usage_weight: float = lerp(1.0, skill_ratio, clamp(preference_for_best, 0.0, 1.0))
		var attackability: float = clamp(1.2 - difficulty * 0.7, 0.35, 1.25)
		var total_weight: float = max(0.01, tendency_weight * hitter_usage_weight * attackability)
		var enriched: Dictionary = option.duplicate(true)
		enriched["attack_weight"] = total_weight
		weighted_options.append(enriched)

	return _weighted_option_choice(weighted_options, "attack_weight", rng)

static func build_defensive_read(
	options: Array[Dictionary],
	attacking_strategy: TeamStrategy,
	defending_strategy: TeamStrategy,
	rng: RandomNumberGenerator
) -> Dictionary:
	if options.is_empty():
		return {}

	var scouting_confidence: float = 0.0
	if defending_strategy != null:
		scouting_confidence = defending_strategy.setter_tendency_scouting_confidence()

	var weighted_options: Array[Dictionary] = []
	for option in options:
		var skill_ratio: float = float(option.get("spike_skill_ratio", 1.0))
		var difficulty: float = float(option.get("set_difficulty", 0.5))
		var real_tendency: float = 1.0
		if attacking_strategy != null:
			real_tendency = attacking_strategy.setting_preference_weight_for_attacker(option.get("attacker"))
		var perceived_tendency: float = lerp(1.0, real_tendency, scouting_confidence)
		var threat_weight: float = max(0.01, perceived_tendency * skill_ratio * clamp(1.15 - difficulty * 0.55, 0.4, 1.25))
		var enriched: Dictionary = option.duplicate(true)
		enriched["perceived_tendency"] = perceived_tendency
		enriched["threat_weight"] = threat_weight
		weighted_options.append(enriched)

	var predicted_primary: Dictionary = _weighted_option_choice(weighted_options, "threat_weight", rng)
	return {
		"scouting_confidence": scouting_confidence,
		"predicted_primary": predicted_primary,
		"weighted_options": weighted_options
	}

static func build_defensive_positioning_plan(
	team_side: float,
	defending_match_data: TeamMatchData,
	defending_strategy: TeamStrategy,
	defensive_read: Dictionary
) -> Dictionary:
	if defending_match_data == null:
		return {}

	var weighted_options: Array = defensive_read.get("weighted_options", [])
	if weighted_options.is_empty():
		return {}

	var block_commit: float = 1.0
	if defending_strategy != null:
		block_commit = defending_strategy.block_commit_tendency

	var threat_center_z: float = _weighted_average_z(weighted_options, "threat_weight")
	var threat_spread: float = _weighted_z_spread(weighted_options, "threat_weight", threat_center_z)
	var blocker_positions: Array[Dictionary] = []
	var backcourt_positions: Array[Dictionary] = []
	var best_primary: Dictionary = {}
	var best_primary_fit: float = -INF
	var sorted_front_row: Array[Dictionary] = []

	for athlete in defending_match_data.court_players:
		var base_position: Vector3 = defending_match_data.get_phase_position_for_player(athlete, "block", team_side, athlete, false)
		var is_front_row: bool = athlete.rotationPosition >= 2 and athlete.rotationPosition <= 4
		if is_front_row:
			var role_pull: float = 1.0 if athlete.role == Enums.Role.Middle else 0.72
			var shifted_z: float = lerp(base_position.z, threat_center_z, clamp(block_commit * role_pull * 0.55, 0.0, 0.95))
			var assignment: Dictionary = {
				"athlete": athlete,
				"athlete_name": _athlete_name(athlete),
				"start_position": Vector3(base_position.x, base_position.y, shifted_z),
				"base_position": base_position,
				"block_role_pull": role_pull
			}
			blocker_positions.append(assignment)

			var predicted_target: Dictionary = defensive_read.get("predicted_primary", {})
			if not predicted_target.is_empty():
				var predicted_contact: Vector3 = predicted_target.get("contact_position", Vector3.ZERO)
				var fit: float = 1.0 / max(abs(shifted_z - predicted_contact.z), 0.35)
				fit *= max(float(athlete.block), 10.0)
				if fit > best_primary_fit:
					best_primary_fit = fit
					best_primary = assignment
			sorted_front_row.append(assignment)
		else:
			backcourt_positions.append({
				"athlete": athlete,
				"athlete_name": _athlete_name(athlete),
				"base_position": base_position,
				"target_position": Vector3(base_position.x, base_position.y, shifted_z_back),
				"move_distance": abs(shifted_z_back - base_position.z),
				"should_move": abs(shifted_z_back - base_position.z) > 0.2 and threat_spread < 2.1
			})

	sorted_front_row.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("base_position", Vector3.ZERO).z) > float(b.get("base_position", Vector3.ZERO).z)
	)
	var lane_assignments := _build_lane_assignments(sorted_front_row)

	return {
		"threat_center_z": threat_center_z,
		"threat_spread": threat_spread,
		"blockers": blocker_positions,
		"backcourt": backcourt_positions,
		"primary_blocker": best_primary,
		"lane_assignments": lane_assignments
	}

static func choose_reacting_blocker(positioning_plan: Dictionary, actual_option: Dictionary) -> AthleteStats:
	var reachable_blockers: Array[Dictionary] = identify_reachable_blockers(positioning_plan, actual_option)
	if reachable_blockers.is_empty():
		return null

	var target_position: Vector3 = actual_option.get("contact_position", Vector3.ZERO)
	var best: AthleteStats = null
	var best_score: float = -INF
	for blocker_plan in reachable_blockers:
		var athlete: AthleteStats = blocker_plan.get("athlete")
		if athlete == null:
			continue
		var start_position: Vector3 = blocker_plan.get("start_position", Vector3.ZERO)
		var fit: float = clamp(1.4 - abs(start_position.z - target_position.z) * 0.22, 0.55, 1.4)
		var score: float = float(athlete.block) * fit
		if score > best_score:
			best_score = score
			best = athlete

	return best

static func identify_reachable_blockers(positioning_plan: Dictionary, actual_option: Dictionary) -> Array[Dictionary]:
	var reachable: Array[Dictionary] = []
	if positioning_plan.is_empty() or actual_option.is_empty():
		return reachable

	var contact_position: Vector3 = actual_option.get("contact_position", Vector3.ZERO)
	var attack_lane: String = str(actual_option.get("attack_lane", "middle"))
	var lane_assignments: Dictionary = positioning_plan.get("lane_assignments", {})
	var prioritized_blockers: Array = lane_assignments.get(attack_lane, [])
	if prioritized_blockers.is_empty():
		prioritized_blockers = positioning_plan.get("blockers", [])

	for blocker_plan_variant in prioritized_blockers:
		var blocker_plan: Dictionary = blocker_plan_variant
		var athlete: AthleteStats = blocker_plan.get("athlete")
		if athlete == null:
			continue
		var start_position: Vector3 = blocker_plan.get("start_position", Vector3.ZERO)
		var lateral_reach: float = max(float(athlete.height) / 3.0, 0.55)
		var reaches_lane: bool = abs(contact_position.z - start_position.z) <= lateral_reach
		var reaches_height: bool = contact_position.y <= float(athlete.blockHeight)
		if not reaches_lane or not reaches_height:
			continue

		var enriched_plan: Dictionary = blocker_plan.duplicate(true)
		enriched_plan["lane_delta"] = abs(contact_position.z - start_position.z)
		enriched_plan["lateral_reach"] = lateral_reach
		enriched_plan["height_margin"] = float(athlete.blockHeight) - contact_position.y
		reachable.append(enriched_plan)

	return reachable

static func _eligible_attackers(team_match_data: TeamMatchData, setter: AthleteStats) -> Array[AthleteStats]:
	var attackers: Array[AthleteStats] = []
	if team_match_data == null:
		return attackers

	for athlete in team_match_data.court_players:
		if athlete == null or athlete == setter:
			continue
		if athlete.role == Enums.Role.Libero:
			continue
		if athlete.spike <= 0.0:
			continue
		attackers.append(athlete)

	return attackers

static func _attack_contact_position(team_match_data: TeamMatchData, attacker: AthleteStats, team_side: float) -> Vector3:
	var contact_position: Vector3 = team_match_data.get_phase_position_for_player(attacker, "attack", team_side, attacker, true)
	var attack_height: float = max(float(attacker.spikeHeight), 2.2)
	if attacker.rotationPosition < 2 or attacker.rotationPosition > 4:
		attack_height = max(attack_height - 0.08, 2.25)
	return Vector3(contact_position.x, attack_height, contact_position.z)

static func _set_difficulty(
	set_origin: Vector3,
	contact_position: Vector3,
	flight_time: float,
	attacker: AthleteStats,
	team_side: float,
	setter_reference_height: float
) -> float:
	var time_cost: float = clamp((flight_time - 0.28) / 0.95, 0.0, 1.0)
	var angle_cost := 0.0
	if attacker.rotationPosition >= 2 and attacker.rotationPosition <= 4:
		angle_cost = _front_court_angle_cost(set_origin, contact_position)
	else:
		angle_cost = _back_court_angle_cost(set_origin, contact_position, setter_reference_height, team_side)
	return clamp(time_cost * 0.58 + angle_cost * 0.42, 0.0, 1.0)

static func _front_court_angle_cost(set_origin: Vector3, contact_position: Vector3) -> float:
	var direction := Vector3(contact_position.x - set_origin.x, 0.0, contact_position.z - set_origin.z)
	if direction.length() <= 0.001:
		return 0.0
	var angle: float = min(direction.angle_to(Vector3.FORWARD), direction.angle_to(Vector3.BACK))
	return clamp(angle / (PI * 0.5), 0.0, 1.0)

static func _back_court_angle_cost(set_origin: Vector3, contact_position: Vector3, perfect_height: float, team_side: float) -> float:
	var perfect_origin := Vector3(team_side * PERFECT_PASS_SETTER_X, perfect_height, 0.0)
	var actual_direction := Vector3(contact_position.x - set_origin.x, 0.0, contact_position.z - set_origin.z)
	var perfect_direction := Vector3(contact_position.x - perfect_origin.x, 0.0, contact_position.z - perfect_origin.z)
	if actual_direction.length() <= 0.001 or perfect_direction.length() <= 0.001:
		return 0.0
	return clamp(actual_direction.angle_to(perfect_direction) / (PI * 0.5), 0.0, 1.0)

static func _minimum_speed_trajectory(start_pos: Vector3, target: Vector3) -> Dictionary:
	var high_arc: Dictionary = _binary_search_trajectory(start_pos, target, true)
	var low_arc: Dictionary = _binary_search_trajectory(start_pos, target, false)

	if high_arc.is_empty():
		return low_arc
	if low_arc.is_empty():
		return high_arc
	if float(low_arc.get("time", INF)) < float(high_arc.get("time", INF)):
		return low_arc
	return high_arc

static func _binary_search_trajectory(start_pos: Vector3, target: Vector3, aiming_up: bool) -> Dictionary:
	var high_velocity = _find_parabola_for_given_speed(start_pos, target, MAX_SET_VELOCITY, aiming_up)
	if high_velocity == null:
		return {}

	var low := MIN_BINARY_SEARCH_SPEED
	var high := MAX_SET_VELOCITY
	var best_velocity: Vector3 = high_velocity
	for _i in range(BINARY_SEARCH_STEPS):
		var mid: float = (low + high) * 0.5
		var mid_velocity = _find_parabola_for_given_speed(start_pos, target, mid, aiming_up)
		if mid_velocity == null:
			low = mid
			continue
		best_velocity = mid_velocity
		high = mid

	var flight_time: float = _time_till_ball_at_position(start_pos, best_velocity, target)
	if is_inf(flight_time) or is_nan(flight_time):
		return {}

	return {
		"velocity": best_velocity,
		"time": flight_time,
		"aiming_up": aiming_up
	}

static func _find_parabola_for_given_speed(start_pos: Vector3, target: Vector3, speed: float, aiming_up: bool) -> Variant:
	var g: float = GRAVITY
	var xz_direction := target - start_pos
	xz_direction.y = 0.0

	var xz_dist := Vector3(start_pos.x, 0.0, start_pos.z).distance_to(Vector3(target.x, 0.0, target.z))
	var y_dist := target.y - start_pos.y
	if xz_dist <= 0.001:
		return Vector3.ZERO if abs(y_dist) <= 0.001 else null

	var discriminant := pow(speed, 4) - g * (g * xz_dist * xz_dist + 2.0 * y_dist * speed * speed)
	if discriminant < 0.0:
		return null

	var angle1 := atan((speed * speed + sqrt(discriminant)) / (g * xz_dist))
	var angle2 := atan((speed * speed - sqrt(discriminant)) / (g * xz_dist))
	var ideal_angle: float = max(angle1, angle2) if aiming_up else min(angle1, angle2)

	var projectile_velocity := Vector3.ZERO
	projectile_velocity.y = speed * sin(ideal_angle)
	var xz_speed: float = speed * cos(ideal_angle)
	var normalized_direction: Vector3 = xz_direction.normalized()
	projectile_velocity.x = normalized_direction.x * xz_speed
	projectile_velocity.z = normalized_direction.z * xz_speed
	return projectile_velocity

static func _time_till_ball_at_position(position: Vector3, linear_velocity: Vector3, reception_target: Vector3) -> float:
	var ball_xz_speed := Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
	if ball_xz_speed <= 0.0:
		return INF
	var ball_xz_distance := Vector3(position.x - reception_target.x, 0.0, position.z - reception_target.z).length()
	return ball_xz_distance / ball_xz_speed

static func _weighted_option_choice(options: Array[Dictionary], weight_key: String, rng: RandomNumberGenerator) -> Dictionary:
	if options.is_empty():
		return {}

	var total: float = 0.0
	for option in options:
		total += max(0.0, float(option.get(weight_key, 0.0)))
	if total <= 0.0:
		return options[0]

	var roll: float = rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for option in options:
		cumulative += max(0.0, float(option.get(weight_key, 0.0)))
		if roll <= cumulative:
			return option

	return options[0]

static func _weighted_average_z(options: Array, weight_key: String) -> float:
	var total: float = 0.0
	var weighted: float = 0.0
	for option in options:
		var contact_position: Vector3 = option.get("contact_position", Vector3.ZERO)
		var weight: float = max(0.0, float(option.get(weight_key, 0.0)))
		total += weight
		weighted += contact_position.z * weight
	if total <= 0.0:
		return 0.0
	return weighted / total

static func _weighted_z_spread(options: Array, weight_key: String, center_z: float) -> float:
	var total: float = 0.0
	var weighted: float = 0.0
	for option in options:
		var contact_position: Vector3 = option.get("contact_position", Vector3.ZERO)
		var weight: float = max(0.0, float(option.get(weight_key, 0.0)))
		total += weight
		weighted += abs(contact_position.z - center_z) * weight
	if total <= 0.0:
		return 0.0
	return weighted / total

static func _build_lane_assignments(sorted_front_row: Array[Dictionary]) -> Dictionary:
	var lane_assignments := {
		"left": [],
		"middle": [],
		"right": []
	}
	if sorted_front_row.is_empty():
		return lane_assignments

	if sorted_front_row.size() == 1:
		for lane in lane_assignments.keys():
			lane_assignments[lane] = [sorted_front_row[0]]
		return lane_assignments

	var left_blocker: Dictionary = sorted_front_row[0]
	var right_blocker: Dictionary = sorted_front_row[sorted_front_row.size() - 1]
	var middle_index: int = mini(1, sorted_front_row.size() - 1)
	if sorted_front_row.size() >= 3:
		middle_index = 1
	var middle_blocker: Dictionary = sorted_front_row[middle_index]

	lane_assignments["left"] = _compact_blocker_group([left_blocker, middle_blocker])
	lane_assignments["middle"] = _compact_blocker_group([middle_blocker, left_blocker, right_blocker])
	lane_assignments["right"] = _compact_blocker_group([right_blocker, middle_blocker])
	return lane_assignments

static func _compact_blocker_group(candidates: Array) -> Array[Dictionary]:
	var unique_by_name := {}
	var compacted: Array[Dictionary] = []
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var athlete: AthleteStats = candidate.get("athlete")
		if athlete == null:
			continue
		var athlete_name := _athlete_name(athlete)
		if unique_by_name.has(athlete_name):
			continue
		unique_by_name[athlete_name] = true
		compacted.append(candidate)
	return compacted

static func _role_bucket(attacker: AthleteStats) -> String:
	if attacker.role == Enums.Role.Middle:
		return "middle"
	if attacker.role == Enums.Role.Outside or attacker.role == Enums.Role.Opposite:
		return "outside"
	return "other"

static func _court_bucket(attacker: AthleteStats) -> String:
	if attacker.rotationPosition >= 2 and attacker.rotationPosition <= 4:
		return "front"
	return "back"

static func _attack_lane(attacker: AthleteStats, contact_position: Vector3) -> String:
	if attacker.role == Enums.Role.Middle:
		return "middle"
	if contact_position.z >= 1.2:
		return "left"
	if contact_position.z <= -1.2:
		return "right"
	return "middle"

static func _athlete_name(athlete: AthleteStats) -> String:
	if athlete == null:
		return ""
	return "%s %s" % [athlete.firstName, athlete.lastName]
