class_name LoadTrackingStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func apply_rally_load(player: AthleteStats, ctx: RallyState) -> void:
	log.log("load", "Applying movement and action load for rally event.", player.team, player)
	# TODO: Track movement distance, jumps, dives, landings, and action strain during the rally.
