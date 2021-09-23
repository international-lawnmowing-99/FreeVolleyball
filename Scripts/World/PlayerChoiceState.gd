extends Node

class_name PlayerChoiceState

# r = new System.Random(Guid.NewGuid().GetHashCode());

var continentIndex:int = -1;
var nationIndices = []
var clubTeamIndices = []

func _init(gameWorld):
	nationIndices.resize(7)
	for i in range(7):
		nationIndices[i] = -1;
		clubTeamIndices[i] = []
		clubTeamIndices[i].resize(gameWorld.continents[i].nations.size())
		for j in range(0, clubTeamIndices[i].size()):
			clubTeamIndices[i][j] = -1;

func ChooseRandom(gameWorld:World, mode):
	var r = RandomNumberGenerator.new()
	r.randomize()
	
	var state = PlayerChoiceState.new(gameWorld)

	if mode == NewMatchData.ClubOrInternational.International:
		state.continentIndex = r.randi_range(0,gameWorld.continents.size());
		state.nationIndices[state.continentIndex] = r.randi_range(0, gameWorld.continents[state.continentIndex].nations.size());
	else:
		state.continentIndex = r.randi_range(gameWorld.continents.size());
		state.nationIndices[state.continentIndex] = r.randi_range(0, gameWorld.continents[state.continentIndex].nations.size());
		state.clubTeamIndices[state.continentIndex][state.nationIndices[state.continentIndex]] = \
			r.randi_range(gameWorld.continents[state.continentIndex].nations[state.nationIndices[state.continentIndex]].league.clubTeams.size());
	return state
