extends Attempt
class_name ServeAttempt

enum ServeType {
	UNDERARM,
	FLOAT,
	JUMP
}

enum ServeAggression {
	SAFETY,
	MODERATE,
	AGGRESSIVE
}

const BASE_SERVE_ERROR_PROBABILITY: float = 0.0

func resolve() -> ServeOutcome:
	var outcome: ServeOutcome = ServeOutcome.new()
	var serve_type: int = _planned_serve_type()
	var serve_aggression: int = _planned_serve_aggression()
	var attack_target: Vector3 = ctx.serve_target
	var topspin: float = 1.0
	var serve_error_probability: float = _serve_error_probability(serve_aggression)
	var roll: float = rng.randf()
	var receive_difficulty_rating: float = _receive_difficulty_rating(serve_aggression)
	receive_difficulty_rating += _targeting_difficulty_modifier()
	receive_difficulty_rating = clamp(receive_difficulty_rating, 0.0, 100.0)

	if serve_type == ServeType.JUMP:
		topspin = 1.0 + rng.randf_range(0.5, 1.8)

	outcome.actor = actor
	ctx.serve_execution = float(clamp(receive_difficulty_rating / 100.0, 0.0, 1.0))
	ctx.serve_receive_difficulty = float(clamp(receive_difficulty_rating / 100.0, 0.05, 1.0))

	outcome.metadata["action"] = "serve"
	outcome.metadata["serve_type"] = _serve_type_name(serve_type)
	outcome.metadata["serve_aggression"] = _serve_aggression_name(serve_aggression)
	outcome.metadata["attack_target"] = _serialize_vector3(attack_target)
	outcome.metadata["serve_target_strategy"] = ctx.serve_target_strategy
	outcome.metadata["target_receiver_name"] = ctx.serve_target_receiver_name
	outcome.metadata["target_receiver_reception"] = ctx.serve_target_reception
	outcome.metadata["topspin"] = topspin
	outcome.metadata["floating"] = serve_type == ServeType.FLOAT
	outcome.metadata["execution"] = ctx.serve_execution
	outcome.metadata["receive_difficulty"] = ctx.serve_receive_difficulty
	outcome.metadata["receive_difficulty_rating"] = receive_difficulty_rating
	outcome.metadata["serve_error_probability"] = serve_error_probability
	outcome.metadata["roll"] = roll

	if roll < serve_error_probability:
		outcome.success = false
		outcome.service_error = true
		outcome.terminal = true
		outcome.point_winner = ctx.defender
		outcome.metadata["result"] = "service_error"
	else:
		outcome.success = true
		outcome.terminal = false
		outcome.metadata["result"] = "in_play"

	return outcome

func _choose_serve_type() -> int:
	return rng.randi_range(0, 2)

func _choose_serve_aggression() -> int:
	return rng.randi_range(0, 2)

func _planned_serve_type() -> int:
	match ctx.serve_type:
		"underarm":
			return ServeType.UNDERARM
		"jump":
			return ServeType.JUMP
		_:
			return ServeType.FLOAT

func _planned_serve_aggression() -> int:
	match ctx.serve_aggression:
		"safety":
			return ServeAggression.SAFETY
		"aggressive":
			return ServeAggression.AGGRESSIVE
		_:
			return ServeAggression.MODERATE

func _serve_error_probability(serve_aggression: int) -> float:
	var error_probability: float = BASE_SERVE_ERROR_PROBABILITY

	match serve_aggression:
		ServeAggression.AGGRESSIVE:
			error_probability *= 2.0
		ServeAggression.SAFETY:
			error_probability /= 2.0

	return error_probability

func _receive_difficulty_rating(serve_aggression: int) -> float:
	match serve_aggression:
		ServeAggression.AGGRESSIVE:
			return rng.randf_range(float(actor.serve) * 2.0 / 3.0, float(actor.serve))
		ServeAggression.MODERATE:
			return rng.randf_range(float(actor.serve) / 3.0, float(actor.serve) * 2.0 / 3.0)
		_:
			return rng.randf_range(0.0, float(actor.serve) / 3.0)

func _targeting_difficulty_modifier() -> float:
	if ctx.serve_target_receiver_name == "":
		match ctx.serve_target_strategy:
			"target_seam":
				return 6.0
			"target_short_zone":
				return 3.0
			"target_deep_middle":
				return 2.0
			_:
				return 0.0

	var reception_delta: float = 50.0 - ctx.serve_target_reception
	match ctx.serve_target_strategy:
		"target_weakest_receiver":
			return 7.0 + reception_delta * 0.18
		"target_middle_attacker":
			return 5.0 + reception_delta * 0.12
		"target_strongest_receiver":
			return -4.0 + reception_delta * 0.08
		"target_libero":
			return -6.0 + reception_delta * 0.08
		_:
			return reception_delta * 0.1

func _serve_type_name(serve_type: int) -> String:
	match serve_type:
		ServeType.UNDERARM:
			return "underarm"
		ServeType.FLOAT:
			return "float"
		_:
			return "jump"

func _serve_aggression_name(serve_aggression: int) -> String:
	match serve_aggression:
		ServeAggression.SAFETY:
			return "safety"
		ServeAggression.MODERATE:
			return "moderate"
		_:
			return "aggressive"

func _serialize_vector3(value: Vector3) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
		"z": value.z
	}
