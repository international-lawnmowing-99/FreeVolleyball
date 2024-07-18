extends Resource
class_name ScheduledMatch

@export var toBeSimulated:bool = false
@export var date:String
@export var round:int
@export var teamA:TeamResource
@export var teamB:TeamResource

#@export var venue:String

@export var completed:bool = false

@export var winner:TeamResource

@export var teamASetScore:int
@export var teamBSetScore:int

@export var teamACompletedScores = []
@export var teamBCompletedScores = []
