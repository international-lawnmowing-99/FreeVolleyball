extends Resource

class_name PlayerChoiceState

#var clubOrInternational:Enums.ClubOrInternational = Enums.ClubOrInternational.NotSelected
@export var continentIndex:int = -1

# for every continent, which team is selected?
@export var nationIndices:Array = []
# for every [continent][nation on that continent], which club is selected
@export var clubTeamIndices:Array[Array] = []

func _init(gameWorld = GameWorld.new()):
	if !gameWorld.continents:
		gameWorld.GenerateDefaultWorld(false)
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
