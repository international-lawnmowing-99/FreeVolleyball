class_name LoadTrackingStage
extends RefCounted

var event_log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	event_log = _log

func apply_rally_load(player: AthleteStats, _ctx: RallyState) -> void:
	event_log.log("load", "Applying movement and action load for rally event.", player.team, player)
	# TODO: Track movement distance, jumps, dives, landings, and action strain during the rally.
