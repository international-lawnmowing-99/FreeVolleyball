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

var is_terminal: bool = false
var point_winner: TeamData = null

var attacker: TeamData
var defender: TeamData
var attacker_match_data: TeamMatchData
var defender_match_data: TeamMatchData
var rally_over: bool = false
