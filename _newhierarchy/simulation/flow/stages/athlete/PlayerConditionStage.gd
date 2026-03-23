class_name PlayerConditionStage
extends RefCounted

var log: SimulationEventLog

func _init(_log: SimulationEventLog) -> void:
	log = _log

func update_form(team: TeamData) -> void:
	log.log("form", "Updating player form state.", team)
	apply_base_form_cycles(team)
	apply_training_form_effects(team)
	apply_match_form_effects(team)

func update_injuries(team: TeamData) -> void:
	log.log("injury", "Updating injury state.", team)
	process_training_injuries(team)
	process_match_injuries(team)

func apply_base_form_cycles(team: TeamData) -> void:
	log.log("form", "Applying base stacked form cycles.", team)
	# TODO: Drive form changes with stacked sine-like waves over time.

func apply_training_form_effects(team: TeamData) -> void:
	log.log("form", "Applying training-driven form effects.", team)
	# TODO: Add training-load and training-quality impacts on form.

func apply_match_form_effects(team: TeamData) -> void:
	log.log("form", "Applying match-performance form effects.", team)
	# TODO: Add separate form effects from recent match performance.

func process_training_injuries(team: TeamData) -> void:
	log.log("injury", "Processing training injuries.", team)
	# TODO: Resolve acute injuries and ongoing niggles created or aggravated in training.

func process_match_injuries(team: TeamData) -> void:
	log.log("injury", "Processing match injuries.", team)
	# TODO: Resolve acute injuries and ongoing niggles created or aggravated in matches.
