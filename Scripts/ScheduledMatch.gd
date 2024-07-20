extends Resource
class_name ScheduledMatch

@export var toBeSimulated:bool = false
@export var date:String
@export var round:int
@export var teamA:TeamData
@export var teamB:TeamData

#@export var venue:String

@export var completed:bool = false

@export var winner:TeamData

@export var teamASetScore:int
@export var teamBSetScore:int

@export var teamACompletedScores = []
@export var teamBCompletedScores = []
