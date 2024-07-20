extends Resource
class_name TeamStrategy
#Holds all the input the user/ai has generated to direct their team

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

var libero1:Athlete
var libero2:Athlete

@export var playerToLiberoServe = []
@export var playerToLiberoReceive = []
