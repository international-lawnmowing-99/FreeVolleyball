class_name Attempt
extends RefCounted

var actor:AthleteStats
var ctx: RallyState
var rng: RandomNumberGenerator

func _init(_actor, _ctx: RallyState, _rng: RandomNumberGenerator) -> void:
	actor = _actor
	ctx = _ctx
	rng = _rng

func resolve() -> AttemptOutcome:
	push_error("resolve() must be implemented by subclass")
	return null
