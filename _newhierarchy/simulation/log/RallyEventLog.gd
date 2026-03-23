class_name RallyEventLog
extends RefCounted

var events: Array[AttemptOutcome] = []
var ball_touches: Array[Dictionary] = []
var context_snapshots: Array[Dictionary] = []

func add(outcome: AttemptOutcome) -> void:
	events.append(outcome)

func add_ball_touch(snapshot: Dictionary) -> void:
	ball_touches.append(snapshot)

func add_context_snapshot(snapshot: Dictionary) -> void:
	context_snapshots.append(snapshot)

func serialize_for_replay() -> Dictionary:
	var serialized_events: Array[Dictionary] = []
	for outcome in events:
		var actor_name := "Unknown Athlete"
		if outcome.actor != null:
			actor_name = "%s %s" % [outcome.actor.firstName, outcome.actor.lastName]

		serialized_events.append({
			"action": str(outcome.metadata.get("action", "")),
			"actor_name": actor_name,
			"success": outcome.success,
			"terminal": outcome.terminal,
			"result": str(outcome.metadata.get("result", "")),
			"metadata": outcome.metadata.duplicate(true)
		})

	return {
		"events": serialized_events,
		"ball_touches": ball_touches.duplicate(true),
		"context_snapshots": context_snapshots.duplicate(true)
	}
