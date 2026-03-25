class_name RallyState
extends RefCounted

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

var is_terminal: bool = false
var point_winner: TeamData = null

var attacker: TeamData
var defender: TeamData
var attacker_match_data: TeamMatchData
var defender_match_data: TeamMatchData
var rally_over: bool = false
