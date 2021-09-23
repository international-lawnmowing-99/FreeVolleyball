extends Node

class_name GameWorld
		#System.Random r = new System.Random();
var firstNames = []
var lastNames = []
		#public GameObject loadingScreen;

		#// There are players, organised in teams, in competitions, national teams, national competitions, and it's organised by continent for ease of navigation
var continents = []
		



func GenerateDefaultWorld():
	LoadNames()
	var r = RandomNumberGenerator.new()
	r.randomize()

	var nationsText = File.ReadAllLines("res://Data/NationsAndPop.txt");

	for i in range(nationsText.size()):
		if (nationsText[i - 1].size() == 0 && nationsText[i + 1].size() == 0):
			continents.append(Continent.new(nationsText[i]))
			
		elif (nationsText[i].Length > 0):#// && currentContinent > -1)
			var split = nationsText[i].Split()

			#if split[split.Length - 1] != split[split.Length - 2]:
			if split[split.Length - 2] == "-----":
				split[split.Length - 2] = split[split.Length - 1]

			var finalName = ""

			for j in range(split.size()-3):
				finalName += split[j] + " "

			var pop:int = 0

			pop =  int(split[split.Length - 3])

			continents[continents.Count - 1].nations.append(Nation.new(finalName, pop))
			var currentNation = continents[continents.Count - 1].nations[continents[continents.Count - 1].nations.Count - 1]

			currentNation.Populate(firstNames, lastNames, r);

func GetTeam(choiceState, mode):
	if (mode == NewMatchData.ClubOrInternational.Club):
		return continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].league.clubTeams[choiceState.clubTeamIndices[choiceState.continentIndex][choiceState.nationIndices[choiceState.continentIndex]]]
	else:
		return continents[choiceState.continentIndex].nations[choiceState.nationIndices[choiceState.continentIndex]].nationalTeam

func LoadNames():
	firstNames = File.ReadAllLines("res://Data/firstNames.txt")
	lastNames = File.ReadAllLines("res://Data/lastNames.txt");
