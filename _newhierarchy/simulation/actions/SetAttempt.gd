extends Attempt
class_name SetAttempt

const GRAVITY: float = 9.8
const SET_TOPSPIN: float = 0.35
const MAX_SET_SPEED: float = 10.0

func resolve() -> SetOutcome:
	var outcome := SetOutcome.new()
	var chosen_option: Dictionary = ctx.chosen_set_option
	var set_origin: Vector3 = ctx.last_pass_target if ctx.last_pass_target != Vector3.ZERO else ctx.ball_position
	var desired_target: Vector3 = chosen_option.get("contact_position", Vector3.ZERO)
	var desired_velocity: Vector3 = chosen_option.get("set_velocity", Vector3.ZERO)
	var difficulty: float = float(chosen_option.get("set_difficulty", 0.45))
	var error_threshold: float = 100.0 * pow((actor.set / 100.0 - 1.0), 8.0)
	var perfect_threshold: float = 100.0 - 100.0 / (1.0 + pow(2.71828, -((actor.set / 100.0) - 0.5) / 0.1))
	var set_execution: float = rng.randf_range(0.0, 100.0)
	var projected_velocity: Vector3 = desired_velocity
	var actual_target: Vector3 = desired_target
	var set_result: String = "attackable_ball"
	var set_quality: String = "perfect"

	outcome.actor = actor
	outcome.success = true
	outcome.metadata["roll"] = set_execution
	outcome.metadata["action"] = "set"
	outcome.metadata["set_difficulty"] = difficulty
	outcome.metadata["target_attacker_name"] = str(chosen_option.get("attacker_name", ""))
	outcome.metadata["set_time"] = float(chosen_option.get("set_time", 0.0))
	outcome.metadata["set_lane"] = str(chosen_option.get("attack_lane", ""))
	outcome.metadata["set_court_bucket"] = str(chosen_option.get("court_bucket", ""))
	outcome.metadata["error_threshold"] = error_threshold
	outcome.metadata["perfect_threshold"] = perfect_threshold

	if set_execution < error_threshold or desired_target == Vector3.ZERO:
		outcome.success = false
		outcome.terminal = true
		outcome.point_winner = ctx.attacker
		set_result = "setting_error"
		set_quality = "error"
		#outcome.metadata["result"] = set_result
		outcome.metadata["set_quality"] = set_quality
		return outcome

	if set_execution > perfect_threshold:
		projected_velocity = _perfect_set_velocity(set_origin, desired_target, desired_velocity)
		if projected_velocity == Vector3.ZERO or projected_velocity.length() > MAX_SET_SPEED:
			outcome.success = false
			outcome.terminal = true
			outcome.point_winner = ctx.attacker
			set_result = "setting_error"
			set_quality = "error"
			#outcome.metadata["result"] = set_result
			outcome.metadata["set_quality"] = set_quality
			return outcome
		actual_target = desired_target
		set_quality = "perfect"
	else:
		projected_velocity = _bad_set_velocity(set_origin, desired_target, desired_velocity, perfect_threshold, set_execution)
		var adjusted_target = _ball_position_at_given_height(set_origin, projected_velocity, desired_target.y, 1.0)
		if adjusted_target == null:
			outcome.success = false
			outcome.terminal = true
			outcome.point_winner = ctx.attacker
			set_result = "setting_error"
			set_quality = "error"
			#outcome.metadata["result"] = set_result
			outcome.metadata["set_quality"] = set_quality
			return outcome
		actual_target = adjusted_target
		set_quality = "imperfect"
		set_result = "attackable_ball"

	outcome.metadata["projected_velocity"] = _serialize_vector3(projected_velocity)
	outcome.metadata["projected_topspin"] = SET_TOPSPIN
	outcome.metadata["projected_target_position"] = _serialize_vector3(actual_target)
	outcome.metadata["projected_flight_time"] = _time_till_ball_at_position(set_origin, projected_velocity, actual_target)
	outcome.metadata["set_quality"] = set_quality
	#outcome.metadata["result"] = set_result

	# Carry the old project behavior forward by letting an imperfect set move the attack contact.
	ctx.chosen_set_option["contact_position"] = actual_target
	ctx.chosen_set_option["set_velocity"] = projected_velocity
	ctx.chosen_set_option["set_speed"] = projected_velocity.length()
	ctx.chosen_set_option["set_time"] = float(outcome.metadata["projected_flight_time"])
	ctx.chosen_set_option["set_difficulty"] = clamp(
		float(ctx.chosen_set_option.get("set_difficulty", difficulty)) + (0.18 if set_quality == "imperfect" else 0.0),
		0.0,
		1.0
	)

	if outcome.success:
		outcome.terminal = false
	else:
		outcome.terminal = true
		outcome.point_winner = ctx.attacker

	return outcome

func _perfect_set_velocity(set_origin: Vector3, desired_target: Vector3, desired_velocity: Vector3) -> Vector3:
	if desired_velocity != Vector3.ZERO and desired_velocity.length() <= MAX_SET_SPEED:
		return desired_velocity

	if desired_target.y <= set_origin.y:
		var downward_velocity: Variant = _find_downwards_parabola(set_origin, desired_target)
		return downward_velocity if downward_velocity != null else Vector3.ZERO

	var set_max_height: float = max(desired_target.y + 0.9, set_origin.y + 0.6)
	return _find_well_behaved_parabola(set_origin, desired_target, set_max_height)

func _bad_set_velocity(
	set_origin: Vector3,
	desired_target: Vector3,
	theoretical_velocity: Vector3,
	perfect_threshold: float,
	set_execution: float
) -> Vector3:
	var ideal_velocity: Vector3 = theoretical_velocity
	if ideal_velocity == Vector3.ZERO:
		ideal_velocity = _perfect_set_velocity(set_origin, desired_target, theoretical_velocity)

	var xz_length: float = Vector3(ideal_velocity.x, 0.0, ideal_velocity.z).length()
	if xz_length <= 0.001:
		return ideal_velocity

	var theoretical_xz_angle: float = _signed_angle(Vector3(1, 0, 0), Vector3(desired_target.x - set_origin.x, 0, desired_target.z - set_origin.z), Vector3.UP)
	var theoretical_y_angle: float = atan(ideal_velocity.y / xz_length)
	var difference: float = clamp((perfect_threshold - set_execution) / 100.0, 0.05, 1.0)
	var xz_error: float = rng.randf() * 0.35 * difference
	var y_error: float = rng.randf() * 0.45 * difference
	var speed_error: float = rng.randf() * 0.25 * difference

	var xz_angle: float = theoretical_xz_angle * (1.0 + _random_sign() * xz_error)
	var y_angle: float = theoretical_y_angle * (1.0 + y_error)
	var speed: float = min(MAX_SET_SPEED, ideal_velocity.length() * (1.0 + _random_sign() * speed_error))

	var y_velocity: float = speed * sin(y_angle)
	var xz_velocity: float = speed * cos(y_angle)
	var x_velocity: float = xz_velocity * cos(xz_angle)
	var z_velocity: float = xz_velocity * sin(-xz_angle)
	return Vector3(x_velocity, y_velocity, z_velocity)

func _signed_angle(from: Vector3, to: Vector3, up: Vector3) -> float:
	if from == to or from == up or up == to:
		return 0.001
	var cross_to: Vector3 = from.cross(to)
	var unsigned_angle: float = atan2(cross_to.length(), from.dot(to))
	var angle_sign: float = cross_to.dot(up)
	return -unsigned_angle if angle_sign < 0.0 else unsigned_angle

func _random_sign() -> int:
	return -1 if rng.randf() < 0.5 else 1

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

func _find_downwards_parabola(start_position: Vector3, end_position: Vector3) -> Variant:
	var y_distance: float = start_position.y - end_position.y
	if y_distance < 0.0:
		return null

	var xz_distance: float = Vector3(start_position.x, 0.0, start_position.z).distance_to(Vector3(end_position.x, 0.0, end_position.z))
	if xz_distance < 0.001:
		return Vector3.ZERO

	var xz_theta: float = _signed_angle(Vector3(1, 0, 0), Vector3(end_position.x - start_position.x, 0, end_position.z - start_position.z), Vector3.UP)
	var y_travel_time: float = sqrt(2.0 * y_distance / GRAVITY)
	var max_xz_travel_time: float = xz_distance / MAX_SET_SPEED

	if y_travel_time <= max_xz_travel_time:
		var horizontal_xz_velocity: float = xz_distance / y_travel_time
		return Vector3(horizontal_xz_velocity * cos(-xz_theta), 0.0, horizontal_xz_velocity * sin(-xz_theta))

	var discriminant: float = xz_distance * xz_distance + y_distance * y_distance
	if discriminant < 0.0:
		return null

	var tan_theta: float = (-y_distance + sqrt(discriminant)) / xz_distance
	var denominator: float = xz_distance * tan_theta + y_distance
	if denominator <= 1e-8:
		return null

	var velocity_squared: float = GRAVITY * xz_distance * xz_distance * (1.0 + tan_theta * tan_theta) / (2.0 * denominator)
	if velocity_squared <= 0.0:
		return null

	var speed: float = sqrt(velocity_squared)
	var cos_theta: float = 1.0 / sqrt(1.0 + tan_theta * tan_theta)
	var xz_speed: float = speed * cos_theta
	var y_speed: float = speed * tan_theta * cos_theta
	return Vector3(xz_speed * cos(-xz_theta), y_speed, xz_speed * sin(-xz_theta))

func _time_till_ball_reaches_height(position: Vector3, linear_velocity: Vector3, height: float, gravity_scale: float) -> Variant:
	var gravity: float = GRAVITY * gravity_scale
	var discriminant: float = linear_velocity.y * linear_velocity.y + 2.0 * gravity * (position.y - height)
	if discriminant < 0.0:
		return null

	var final_velocity: float = sqrt(discriminant)
	var remaining_time: float = (final_velocity + linear_velocity.y) / gravity
	if remaining_time < 0.0:
		return null
	return remaining_time

func _ball_position_at_given_height(position: Vector3, linear_velocity: Vector3, height: float, gravity_scale: float) -> Variant:
	var time_of_flight: Variant = _time_till_ball_reaches_height(position, linear_velocity, height, gravity_scale)
	if time_of_flight == null:
		return null

	var xz_position: Vector2 = Vector2(position.x, position.z)
	var xz_velocity: Vector2 = Vector2(linear_velocity.x, linear_velocity.z)
	var new_xz_position: Vector2 = xz_position + xz_velocity * float(time_of_flight)
	return Vector3(new_xz_position.x, height, new_xz_position.y)

func _time_till_ball_at_position(position: Vector3, linear_velocity: Vector3, reception_target: Vector3) -> float:
	var ball_xz_velocity: float = Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()
	if ball_xz_velocity <= 0.0:
		return 0.0

	var ball_xz_distance: float = Vector3(position.x - reception_target.x, 0.0, position.z - reception_target.z).length()
	return ball_xz_distance / ball_xz_velocity

func _serialize_vector3(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}
