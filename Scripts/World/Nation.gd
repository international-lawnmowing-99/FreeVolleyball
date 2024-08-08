extends Resource
class_name Nation

@export var countryName:String
@export var population:int

var nationalTeam:NationalTeam
#Maybe some nations will be able to support more than one sort of league??? Never!
@export var league:Array[TeamData]

func Populate(playerChoiceState:PlayerChoiceState, firstNames:Array[String], lastNames:Array[String], generatematchPlayers:bool):
	var numberOfTeams:int = clamp((population / 700000), 2, 30)
	nationalTeam = NationalTeam.new()
	nationalTeam.teamName = countryName
	#nationalTeam.nation = self

	for clubTeamIndex in range(numberOfTeams):
		playerChoiceState.clubTeamIndices[playerChoiceState.continentIndex][playerChoiceState.nationIndices[playerChoiceState.continentIndex]] = clubTeamIndex
		var team = TeamData.new()
		#team.nation = self
		team.teamName = countryName + " Club Team " + str(clubTeamIndex + 1)
#List<int> shirtNumbers = new List<int>(), images = new List<int>()
#for (int shirt = 0; shirt < 13; shirt++)

#shirtNumbers.Add(shirt + 1);
#images.Add(shirt);

#shirtNumbers = shirtNumbers.OrderBy(x => Guid.NewGuid()).ToList();
#images = images.OrderBy(x => Guid.NewGuid()).ToList();
		if generatematchPlayers:
			team.Populate(playerChoiceState, firstNames, lastNames)
			nationalTeam.nationalPlayers += team.matchPlayers

		league.append(team)

#nationalTeam.CalculateMacroStats();
func _init(nam = "",_pop = 0):
	countryName = nam
	population = _pop
