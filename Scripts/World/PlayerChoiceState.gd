extends Node

class_name PlayerChoiceState
const Enums = preload("res://Scripts/World/Enums.gd")


var continentIndex = -1

var nationIndices = []
var clubTeamIndices = []

func _init(gameWorld):
	nationIndices.resize(7)
	for i in range(7):
		nationIndices[i] = -1
		var arrayt = []
		arrayt.resize(gameWorld.continents[i].nations.size())
		clubTeamIndices.append(arrayt)
		
		for j in range(0, gameWorld.continents[i].nations.size()):
			clubTeamIndices[i][j] = -1;

func ChooseRandom(gameWorld, mode):
	var r = RandomNumberGenerator.new()
	r.randomize()
	
	var state = get_script().new(gameWorld)

	if mode == Enums.ClubOrInternational.International:
		state.continentIndex = r.randi_range(0,gameWorld.continents.size() - 1)
		state.nationIndices[state.continentIndex] = r.randi_range(0, gameWorld.continents[state.continentIndex].nations.size() - 1)
	else:
		state.continentIndex = r.randi_range(0, gameWorld.continents.size() - 1)
		
		state.nationIndices[state.continentIndex] = r.randi_range(0, gameWorld.continents[state.continentIndex].nations.size() - 1)
		state.clubTeamIndices[state.continentIndex][state.nationIndices[state.continentIndex]] = \
			r.randi_range(0, gameWorld.continents[state.continentIndex].nations[state.nationIndices[state.continentIndex]].league.size() - 1)
						#(   gameWorld.continents[state.continentIndex].nations[state.nationIndices[state.continentIndex]].league.clubTeams.Count);

	return state
