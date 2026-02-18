class_name RallyState
extends RefCounted

var event_log := RallyEventLog.new()

var server:AthleteStats
var serving_team: TeamData
var receiving_team: TeamData
var current_team: TeamData

var rally_number: int

var touch_count: int = 0

var is_terminal: bool = false
var point_winner: TeamData = null

var attacker: TeamData
var defender: TeamData
var rally_over: bool = false
