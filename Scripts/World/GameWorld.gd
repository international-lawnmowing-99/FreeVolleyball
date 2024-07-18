extends Resource
class_name GameWorld
const Enums = preload("res://Scripts/World/Enums.gd")

var firstNames = []
var lastNames = []
var nationsText = []
#There are players, organised in teams, in competitions, national teams, national competitions, and it's organised by continent for ease of navigation
@export var continents:Array[Continent] = []
@export var previousGames:Array[ScheduledMatch] = []

# Imagining this should be kept sorted in order of date
@export var upcomingGames:Array[ScheduledMatch] = []

func GenerateDefaultWorld(generatematchPlayers:bool):
	LoadText()
	randomize()

	for i in range(1,nationsText.size()):
		if (nationsText[i - 1].length() == 0 && nationsText[i + 1].length() == 0):
			continents.append(Continent.new(nationsText[i]))

		elif nationsText[i].length() > 0 && nationsText[i] != '/end':
			var _split = split(nationsText[i], [" ", '\t'])

			if _split[_split.size() - 2] == "-----":
				_split[_split.size() - 2] = _split[_split.size() - 1]

			var finalName = ""

			for j in range(_split.size()-3):
				finalName += _split[j] + " "

			var pop:int = 0

			pop =  int(_split[_split.size() - 3])

			continents[continents.size() - 1].nations.append(Nation.new(finalName, pop))

			var currentNation:Nation = continents[continents.size() - 1].nations[continents[continents.size() - 1].nations.size() - 1]

			currentNation.Populate(firstNames, lastNames, generatematchPlayers)

func GetTeam(choiceState:PlayerChoiceState, mode) -> Team:
	if (mode == Enums.ClubOrInternational.Club):
		return continents[choiceState.continentIndex].\
				nations[choiceState.nationIndices[choiceState.continentIndex]].\
				league[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]]
	else:
		return continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam

func LoadText():
	var f = FileAccess.open("res://Data/firstNames.txt", FileAccess.READ_WRITE)
	var g = FileAccess.open("res://Data/lastNames.txt", FileAccess.READ_WRITE)
	var n = FileAccess.open("res://Data/nationsAndPop.txt", FileAccess.READ)

	while not f.eof_reached():
		var line = f.get_line()
		if line != "\n":
			firstNames.append(line)
	while not g.eof_reached():
		lastNames.append(g.get_line())
	while not n.eof_reached():
		nationsText.append(n.get_line())

	f.close()
	g.close()
	n.close()

func split(s: String, delimeters, allow_empty: bool = false) -> Array:
	var parts := []

	var start := 0
	var i := 0

	while i < s.length():
		if s[i] in delimeters:
			if allow_empty or start < i:
				parts.push_back(s.substr(start, i - start))
			start = i + 1
		i += 1

	if allow_empty or start < i:
		parts.push_back(s.substr(start, i - start))

	return parts

func PopulateTeam(team:Team):
	if team is NationalTeam:
		for clubTeam in team.nation.league:
			if clubTeam.matchPlayers.size() > 0:
				Console.AddNewLine("ERROR! Couldn't add more players to full club team!")
			else:
				clubTeam.Populate(firstNames, lastNames)
			team.nationalPlayers += clubTeam.matchPlayers
	else:
		if team.matchPlayers.size() > 0:
			Console.AddNewLine("ERROR! Couldn't add more players to full team!")
		else:
			team.Populate(firstNames, lastNames)

func SimulateDay():
	var simulatedGames:Array = []
	# Find all the games that need to be simulated
	#
	for i in upcomingGames.size():
		if upcomingGames[i].simulate
