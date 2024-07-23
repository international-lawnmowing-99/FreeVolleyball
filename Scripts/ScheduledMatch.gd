extends Resource
class_name ScheduledMatch

@export var toBeSimulated:bool = false
@export var unixDate:int
@export var tournamentRound:int
@export var teamA:TeamData
@export var teamB:TeamData
var string1:String
var string2:String
#@export var venue:String

@export var completed:bool = false

@export var winner:TeamData

@export var teamASetScore:int
@export var teamBSetScore:int

@export var teamACompletedScores = []
@export var teamBCompletedScores = []
