extends Resource
class_name TeamData

# Anything we might want to save goes in here
@export var teamName:String
@export var teamStrategy:TeamStrategy = TeamStrategy.new()
#@export var nation:String
@export var isHuman:bool = false
@export var isLiberoOnCourt:bool
@export var isNextToSpike:bool
@export var markUndoChangesToRoles:bool
@export var matchPlayers:Array[AthleteStats] = []
@export var courtPlayers:Array[AthleteStats] = []
@export var benchPlayers:Array[AthleteStats] = []
@export var rotationsElapsed:int = 0

@export var playerChoiceState:PlayerChoiceState

func Populate(_playerChoiceState, firstNames:Array[String], lastNames:Array[String]):
	playerChoiceState = _playerChoiceState
	#.continentIndex = continentIndex
	#playerChoiceState.nationIndices[continentIndex] = nationIndex
	#playerChoiceState.clubTeamIndices[continentIndex][nationIndex] = clubTeamIndex

	if matchPlayers.size() != 0:
		for i in range (32):
			Console.AddNewLine("!Not Generating additional unnecessary players!! " + teamName)
		return

	for _j in range(12):
		var stats = AthleteStats.new()
		var skill = randf_range(0,10) + randf_range(0,10) + randf_range(0,10) + randf_range(0,10) + randf_range(0,10)
		stats.firstName = firstNames[randi_range(0, firstNames.size() - 1)]
		stats.lastName = lastNames[randi_range(0, lastNames.size() - 1)]
		#stats.nation = nation
		stats.serve = skill + randf_range(0,25) + randf_range(0,25)
		stats.reception = skill + randf_range(0,25) + randf_range(0,25)
		stats.block = skill + randf_range(0,25) + randf_range(0,25)
		stats.set = skill + randf_range(0,25) + randf_range(0,25)
		stats.spike = skill + randf_range(0,25) + randf_range(0,25)
		stats.verticalJump = randf_range(0.1, .5) + randf_range(.1,.5) + randf_range(.1,.5) + randf_range(.35,.6)
		stats.height = randf_range(.25,.6) + randf_range(.25,.6) + randf_range(.35,.6) + randf_range(.35,.6)
		stats.speed = randf_range(5.5,7.5)
		stats.dump = skill + randf_range(0,25) + randf_range(0,25)
		#1.25 is the arm factor of newWoman
		stats.spikeHeight = stats.height * (1.25) + stats.verticalJump
		stats.blockHeight = stats.height * (1.2) + stats.verticalJump

		stats.digHeight = stats.height/1.6
		stats.standingSetHeight = stats.height * 1.2
		stats.jumpSetHeight = stats.standingSetHeight + stats.verticalJump
		var age = 17 + randi()%28

		stats.dob["year"] = 2023 - age
		stats.gameRead = skill/50.0 +  randf()/2.0 * age/(17.0+28.0)

		matchPlayers.append(stats)
