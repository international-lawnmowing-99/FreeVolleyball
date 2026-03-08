extends Resource
class_name TeamStrategy
#Holds all the input the user/ai has generated to direct their team

var teamData:TeamData



@export var defaultReceiveRotations =  [
	# Assuming setter starts in 1
	[#setter in 1
		Vector3(5.5, 0, -4), # pos 1
		Vector3(5.0, 0, -2.8), # pos 2
		Vector3(3, 0, 1.3), # etc...
		Vector3(3.5, 0, 4),
		Vector3(5.3, 0, 2.6),
		Vector3(6.5, 0, 0)
	],
	[#setter in 6
		Vector3(5.5, 0, -1),
		Vector3(3.0, 0, -3.8),
		Vector3(.5, 0, -2.5),
		Vector3(3.5, 0, 4),
		Vector3(5, 0, 1),
		Vector3(1, 0, 0)
	],
	[#setter in 5
		Vector3(5.5, 0, -3.25),
		Vector3(2.75, 0, -3.0),
		Vector3(5, 0, 2.5),
		Vector3(.5, 0, 4),
		Vector3(1.5, 0, 1.3),
		Vector3(6.5, 0, 0)
	],
	[#setter 4
		Vector3(5.5, 0, -4),
		Vector3(5.0, 0, 2.5),
		Vector3(2.75, 0, 3.25),
		Vector3(.5, 0, 4),
		Vector3(6.5, 0, 0),
		Vector3(5, 0, -3.5)
	],
	[#setter 3
		Vector3(5.5, 0, -2.75),
		Vector3(2.75, 0, -1),
		Vector3(0.5, 0, 0),
		Vector3(4.5, 0, 2.5),
		Vector3(6.5, 0, 0),
		Vector3(7.5, 0, -1.75)
	],
	[#setter in 2
		Vector3(5.5, 0, -3),
		Vector3(.5, 0, 0),
		Vector3(5, 0, 2.75),
		Vector3(1.5, 0, 3.75),
		Vector3(7.75, 0, .6),
		Vector3(6.5, 0, 0)
	]
]

@export var teamLineupWeightProfile = TeamLineupWeightProfile.new()
@export var freeBallTarget:Vector3 = Vector3(4.5, 0, 0)
@export var preferredSettingWeights:Array
@export var preferredReceptionWeights:Array
@export var receiveRotations = {
	"default" : defaultReceiveRotations
}
@export var servingTargets:Array
@export var substitutionTirednessThresholds:Array

@export var setOptionWeights:Array

@export var scheduledSubstitutions:Array

# Blocking options
@export var maxCommitDistanceFromNet = 2

@export var playerToLiberoServe = []
@export var playerToLiberoReceive = []

# need to store each player, each of their strategies against each known opposition, and a default, and whether this overrides all others
@export var servingStrategies:Dictionary = {}

func _init(_teamData:TeamData) -> void:
	teamData = _teamData

func choose_starting_rotation() -> int:
	var best_rotation := 0
	var best_score := -INF

	for rotation in range(6):
		var score := score_rotation(rotation)
		if score > best_score:
			best_score = score
			best_rotation = rotation

	return best_rotation


func score_rotation(rotation:int) -> float:
	# Access starting six
	var six := teamData.matchPlayers.slice(0, 6)

	# Apply virtual rotation
	var rotated := []
	for i in range(6):
		rotated.append(six[(i + rotation) % 6])

	var score := 0.0

	# Example heuristics (extend later):
	# Prefer setter starting back row
	if rotated[0].role == Enums.Role.Setter \
	or rotated[4].role == Enums.Role.Setter \
	or rotated[5].role == Enums.Role.Setter:
		score += 1.0

	# Prefer strong passers in back row
	for i in [0,4,5]:
		score += rotated[i].reception * 0.2

	# Prefer strong attackers in front row
	for i in [1,2,3]:
		score += rotated[i].spike * 0.2

	return score
