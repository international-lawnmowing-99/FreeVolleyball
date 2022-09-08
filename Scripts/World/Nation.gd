extends Node

const Athlete = preload("res://Scripts/MatchScene/Athlete.gd")

class_name Nation

var countryName
var population:int

var nationalTeam:NationalTeam
#Maybe some nations will be able to support more than one sort of league??? Never!
var league = []
var players

func Populate(firstNames, lastNames, r, generateAllPlayers:bool):
	var numberOfTeams:int = clamp((population / 700000), 2, 30)
	nationalTeam = NationalTeam.new()
	nationalTeam.teamName = countryName
	nationalTeam.nation = self

	for i in range(numberOfTeams):
		var team = Team.new()
		team.nation = self
		team.teamName = countryName + " Club Team " + str(i + 1)
#List<int> shirtNumbers = new List<int>(), images = new List<int>()
#for (int shirt = 0; shirt < 13; shirt++)

#shirtNumbers.Add(shirt + 1);
#images.Add(shirt);

#shirtNumbers = shirtNumbers.OrderBy(x => Guid.NewGuid()).ToList();
#images = images.OrderBy(x => Guid.NewGuid()).ToList();
		if generateAllPlayers:
			team.Populate(firstNames, lastNames, r)
			nationalTeam.players += team.allPlayers

		league.append(team)

#nationalTeam.CalculateMacroStats();
func _init(nam, _pop):
	countryName = nam
	population = _pop
