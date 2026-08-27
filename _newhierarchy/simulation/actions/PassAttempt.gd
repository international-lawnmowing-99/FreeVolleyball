class_name PassAttempt
extends Attempt

const GRAVITY: float = 9.8
const PASS_TOPSPIN: float = 1.0

func resolve() -> AttemptOutcome:
	var outcome: PassOutcome = PassOutcome.new()
	var receive_difficulty_rating: float = _receive_difficulty_rating()
	var pass_roll: float = rng.randf_range(0.0, float(actor.reception))
	var roll_off_difference: float = pass_roll - receive_difficulty_rating
	var reception_target: Vector3
	var ball_max_height: float
	var result_velocity: Vector3 = Vector3.ZERO

	outcome.actor = actor
	outcome.metadata["action"] = "receive"
	outcome.metadata["pass_roll"] = pass_roll
	outcome.metadata["receive_difficulty_rating"] = receive_difficulty_rating
	outcome.metadata["roll_off_difference"] = roll_off_difference
	outcome.metadata["incoming_ball"] = _serialize_ball_state(ctx.ball_position, ctx.ball_velocity, ctx.ball_topspin)

	if roll_off_difference >= 19.0:
		#pass_band = "perfect"
		reception_target = _perfect_pass_target()
		ball_max_height = _perfect_pass_max_height(reception_target)
		if ball_max_height > 38.0:
			#pass_band = "good"
			reception_target = _good_pass_target()
			ball_max_height = _standard_pass_max_height(reception_target)
		outcome.pass_quality = 1.0
	elif roll_off_difference >= -10.0:
		#pass_band = "good"
		reception_target = _good_pass_target()
		ball_max_height = _standard_pass_max_height(reception_target)
		outcome.pass_quality = 0.75
	elif roll_off_difference >= -50.0:
		#pass_band = "poor"
		reception_target = _poor_pass_target()
		ball_max_height = _standard_pass_max_height(reception_target)
		outcome.pass_quality = 0.4
	else:
		#pass_band = "error"
		var shank_result: Dictionary = _shank_pass_result()
		reception_target = shank_result["target"]
		ball_max_height = float(shank_result["ball_max_height"])
		result_velocity = shank_result["velocity"]
		outcome.pass_quality = 0.1

	if result_velocity == Vector3.ZERO:
		result_velocity = _find_well_behaved_parabola(ctx.ball_position, reception_target, ball_max_height)

	outcome.success = outcome.pass_quality > 0.1
	outcome.terminal = false
	outcome.metadata["reception_target"] = _serialize_vector3(reception_target)
	outcome.metadata["projected_target_position"] = _serialize_vector3(reception_target)
	outcome.metadata["ball_max_height"] = ball_max_height
	outcome.metadata["projected_velocity"] = _serialize_vector3(result_velocity)
	outcome.metadata["projected_topspin"] = PASS_TOPSPIN
	outcome.metadata["projected_flight_time"] = _time_till_ball_at_position(ctx.ball_position, result_velocity, reception_target)

	return outcome

func _receive_difficulty_rating() -> float:
	return float(clamp(ctx.serve_receive_difficulty, 0.05, 1.0) * 100.0)

func _perfect_pass_target() -> Vector3:
	var defender_side: float = _team_side_sign(ctx.defender)
	var setter: AthleteStats = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	var jump_set_height: float = 2.8
	if setter != null:
		jump_set_height = float(setter.jumpSetHeight)

	if setter == actor:
		return Vector3(defender_side * 3.13, jump_set_height, 0.0)

	return Vector3(defender_side * 0.5, jump_set_height, 0.0)

func _perfect_pass_max_height(reception_target: Vector3) -> float:
	var setter: AthleteStats = ctx.defender.teamStrategy.choose_setter(ctx.defender_match_data, rng)
	var setter_speed: float = 6.5
	if setter != null:
		setter_speed = max(float(setter.speed), 0.5)

	var setter_jump_set_time: float = 0.2 + 1.0 + reception_target.distance_to(ctx.ball_position) / setter_speed
	var height_difference_to_target: float = reception_target.y - ctx.ball_position.y
	var initial_y_velocity: float = (
		height_difference_to_target + 0.5 * GRAVITY * setter_jump_set_time * setter_jump_set_time
	) / max(setter_jump_set_time, 0.01)

	return initial_y_velocity * initial_y_velocity / (2.0 * GRAVITY) + ctx.ball_position.y

func _good_pass_target() -> Vector3:
	var defender_side: float = _team_side_sign(ctx.defender)
	return Vector3(
		defender_side * rng.randf_range(1.5, 2.5),
		2.5,
		rng.randf_range(-2.0, 2.0)
	)

func _poor_pass_target() -> Vector3:
	var defender_side: float = _team_side_sign(ctx.defender)
	var target := Vector3(
		ctx.ball_position.x + rng.randf_range(-3.0, 3.0),
		2.5,
		ctx.ball_position.z + rng.randf_range(-3.0, 3.0)
	)

	if defender_side < 0.0:
		target.x = min(target.x, -0.1)
	else:
		target.x = max(target.x, 0.1)

	return target

func _standard_pass_max_height(reception_target: Vector3) -> float:
	return rng.randf_range(reception_target.y + 0.5, reception_target.y + 3.5)

func _shank_pass_result() -> Dictionary:
	var shank_velocity: Vector3 = ctx.ball_velocity
	shank_velocity.y *= -1.0
	shank_velocity *= rng.randf_range(0.2, 0.8)

	var ball_max_height: float = _ball_max_height(ctx.ball_position, shank_velocity, PASS_TOPSPIN)
	var reception_target: Variant
	if ball_max_height >= 2.4:
		reception_target = _ball_position_at_given_height(ctx.ball_position, shank_velocity, 2.5, PASS_TOPSPIN)
	else:
		reception_target = _ball_position_at_given_height(ctx.ball_position, shank_velocity, 0.0, PASS_TOPSPIN)

	if reception_target == null or is_nan(reception_target.x) or is_nan(reception_target.z):
		if ctx.ball_position.y > 0.0:
			reception_target = _ball_position_at_given_height(ctx.ball_position, shank_velocity, 0.0, PASS_TOPSPIN)
		else:
			reception_target = ctx.ball_position
			reception_target.y = 0.0
			shank_velocity = Vector3.ZERO

	return {
		"target": reception_target if reception_target != null else ctx.ball_position,
		"ball_max_height": _ball_max_height(ctx.ball_position, shank_velocity, PASS_TOPSPIN),
		"velocity": shank_velocity
	}

func _time_till_ball_reaches_height(position: Vector3, linear_velocity: Vector3, height: float, gravity_scale: float) -> Variant:
	var g: float = GRAVITY * gravity_scale
	var discriminant: float = linear_velocity.y * linear_velocity.y + 2.0 * g * (position.y - height)
	if discriminant < 0.0:
		return null

	var final_velocity: float = sqrt(discriminant)
	var remaining_time: float = (final_velocity + linear_velocity.y) / g
	if remaining_time < 0.0:
		return null

	return remaining_time

func _ball_position_at_given_height(position: Vector3, linear_velocity: Vector3, height: float, gravity_scale: float) -> Variant:
	var time_of_flight: Variant = _time_till_ball_reaches_height(position, linear_velocity, height, gravity_scale)
	if time_of_flight == null:
		return null

	var xz_position := Vector2(position.x, position.z)
	var xz_velocity := Vector2(linear_velocity.x, linear_velocity.z)
	var new_xz_position: Vector2 = xz_position + xz_velocity * float(time_of_flight)
	return Vector3(new_xz_position.x, height, new_xz_position.y)

func _ball_max_height(position: Vector3, linear_velocity: Vector3, gravity_scale: float) -> float:
	var g: float = GRAVITY * gravity_scale
	if linear_velocity.y < 0.0:
		return position.y

	var time_of_flight: float = linear_velocity.y / g
	var distance_to_travel: float = linear_velocity.y * time_of_flight - 0.5 * g * time_of_flight * time_of_flight
	return position.y + distance_to_travel

func _find_well_behaved_parabola(start_position: Vector3, end_position: Vector3, max_height: float) -> Vector3:
	if max_height <= start_position.y or max_height < end_position.y:
		return Vector3.ZERO

	var xz_distance: float = Vector3(start_position.x, 0.0, start_position.z).distance_to(Vector3(end_position.x, 0.0, end_position.z))
	var y_velocity: float = sqrt(2.0 * GRAVITY * (max_height - start_position.y))
	var time: float = y_velocity / GRAVITY + sqrt(2.0 * GRAVITY * (max_height - end_position.y)) / GRAVITY
	if time <= 0.0:
		return Vector3.ZERO

	var xz_velocity: float = xz_distance / time
	var xz_direction: Vector3 = Vector3(end_position.x - start_position.x, 0.0, end_position.z - start_position.z)
	if xz_direction.length() <= 0.0001:
		return Vector3(0.0, y_velocity, 0.0)

	xz_direction = xz_direction.normalized()
	return Vector3(xz_direction.x * xz_velocity, y_velocity, xz_direction.z * xz_velocity)

func _time_till_ball_at_position(position: Vector3, linear_velocity: Vector3, reception_target: Vector3) -> float:
	var ball_xz_velocity: float = Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
	if ball_xz_velocity <= 0.0:
		return 0.0

	var ball_xz_distance: float = Vector3(position.x - reception_target.x, 0.0, position.z - reception_target.z).length()
	return ball_xz_distance / ball_xz_velocity

func _team_side_sign(team: TeamData) -> float:
	if team == ctx.serving_team:
		return -1.0
	return 1.0

func _result_for_pass_band(pass_band: String) -> String:
	match pass_band:
		"perfect":
			return "perfect_pass"
		"good":
			return "good_pass"
		"poor":
			return "poor_pass"
		_:
			return "shank_pass"

func _description_for_pass_band(pass_band: String) -> String:
	match pass_band:
		"perfect":
			return "Perfect pass to the setter window."
		"good":
			return "Playable two-point pass."
		"poor":
			return "One-point pass that forces adjustment."
		_:
			return "Shanked pass with emergency recovery trajectory."

func _serialize_ball_state(position: Vector3, velocity: Vector3, topspin: float) -> Dictionary:
	return {
		"position": _serialize_vector3(position),
		"velocity": _serialize_vector3(velocity),
		"topspin": topspin
	}

func _serialize_vector3(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}
