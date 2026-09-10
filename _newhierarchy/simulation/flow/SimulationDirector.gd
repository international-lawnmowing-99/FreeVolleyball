class_name SimulationDirector
extends RefCounted

var event_log: SimulationEventLog

var world_bootstrap: WorldBootstrapStage
var national_program: NationalProgramStage
var season_planning: SeasonPlanningStage
var training: TrainingStage
var match_preparation: MatchPreparationStage
var load_tracking: LoadTrackingStage
var point_break: PointBreakStage
var set_review: SetReviewStage
var match_review: MatchReviewStage
var player_condition: PlayerConditionStage

func _init(_log: SimulationEventLog = null) -> void:
	event_log = _log if _log != null else SimulationEventLog.new()
	world_bootstrap = WorldBootstrapStage.new(event_log)
	national_program = NationalProgramStage.new(event_log)
	season_planning = SeasonPlanningStage.new(event_log)
	training = TrainingStage.new(event_log)
	match_preparation = MatchPreparationStage.new(event_log)

	#these belong in the match sim
	point_break = PointBreakStage.new(event_log)
	set_review = SetReviewStage.new(event_log)
	match_review = MatchReviewStage.new(event_log)
	load_tracking = LoadTrackingStage.new(event_log)
	#

	player_condition = PlayerConditionStage.new(event_log)

func generate_game_world(world: SimulationWorldState) -> void:
	world_bootstrap.create_initial_world(world)
	national_program.build_national_teams(world)

func plan_team_season(team: TeamData, plan: TeamSeasonPlan) -> void:
	season_planning.build_season_plan(team, plan)

func run_training_phase(team: TeamData, plan: TeamSeasonPlan) -> void:
	training.run_training_block(team, plan)

func prepare_match(team: TeamData, plan: TeamSeasonPlan, opponent: TeamData) -> void:
	match_preparation.prepare_for_match(team, plan, opponent)

func apply_rally_load(player: AthleteStats, ctx: RallyState) -> void:
	load_tracking.apply_rally_load(player, ctx)

func run_point_break(team: TeamData) -> void:
	point_break.evaluate_post_point(team)

func review_set(team: TeamData) -> void:
	set_review.evaluate_post_set(team)

func review_match(team: TeamData, plan: TeamSeasonPlan) -> void:
	match_review.evaluate_post_match(team, plan)

func update_player_condition(team: TeamData) -> void:
	player_condition.update_form(team)
	player_condition.update_injuries(team)
