class_name RallyState
extends RefCounted

const RallyReplayBuilder = preload("res://_newhierarchy/simulation/replay/RallyReplayBuilder.gd")

var event_log: RallyEventLog = RallyEventLog.new()

var server:AthleteStats
var serving_team: TeamData
var receiving_team: TeamData
var serving_team_match_data: TeamMatchData
var receiving_team_match_data: TeamMatchData
var current_team: TeamData

var rally_number: int

var touch_count: int = 0
var serve_execution: float = 0.5
var serve_receive_difficulty: float = 0.5
var serve_target: Vector3 = Vector3.ZERO
var serve_type: String = ""
var serve_aggression: String = ""
var serve_target_strategy: String = ""
var serve_target_receiver_name: String = ""
var serve_target_reception: float = 0.0
var ball_position: Vector3 = Vector3.ZERO
var ball_velocity: Vector3 = Vector3.ZERO
var ball_topspin: float = 0.0
var ball_time: float = 0.0
var phase_context: Dictionary = {}
var phase_context_history: Array[Dictionary] = []
var step_messages: Array[String] = []
var last_pass_target: Vector3 = Vector3.ZERO
var last_pass_band: String = ""
var last_pass_quality: float = 0.0
var set_options: Array[Dictionary] = []
var chosen_set_option: Dictionary = {}
var defensive_set_read: Dictionary = {}
var defensive_positioning_plan: Dictionary = {}
var chosen_blocker: AthleteStats = null
var available_blockers: Array[AthleteStats] = []
var available_blocker_plans: Array[Dictionary] = []
var movement_time: float = 0.0
var player_tracking_states: Dictionary = {}
var initial_player_tracking_states: Dictionary = {}

var is_terminal: bool = false
var point_winner: TeamData = null

var attacker: TeamData
var defender: TeamData
var attacker_match_data: TeamMatchData
var defender_match_data: TeamMatchData
var rally_over: bool = false

func build_replay_data() -> Dictionary:
	return RallyReplayBuilder.build(self)
