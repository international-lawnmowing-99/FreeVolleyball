class_name RallyEventLog
extends RefCounted

var events: Array[AttemptOutcome] = []

func add(outcome: AttemptOutcome) -> void:
	events.append(outcome)
