extends Node

class_name Nation

var countryName
var population:int

var nationalTeam
#Maybe some nations will be able to support more than one sort of league??? Never!
var league
var players

func Populate(firstNames, lastNames, r:RandomNumberGenerator):


	var numberOfTeams:int = clamp((population / 700000), 2, 30)
	nationalTeam = NationalTeam.new()
	nationalTeam.teamName = countryName

	for i in range(numberOfTeams):
		var team = Team.new()
		team.teamName = countryName + " Club Team " + str(i + 1)
#List<int> shirtNumbers = new List<int>(), images = new List<int>();
#for (int shirt = 0; shirt < 13; shirt++)

#shirtNumbers.Add(shirt + 1);
#images.Add(shirt);

#shirtNumbers = shirtNumbers.OrderBy(x => Guid.NewGuid()).ToList();
#images = images.OrderBy(x => Guid.NewGuid()).ToList();

		for _j in range(12):
			var stats = Stats.new()
			randomize()
			var skill = rand_range(0,50)
			stats.firstName = firstNames[r.randi_range(0, firstNames.size() - 1)]
			stats.lastName = lastNames[r.randi_range(0, lastNames.size() - 1)]
			stats.nation = countryName
			stats.serve = skill + 50 * rand_range(0,50)
			stats.reception = skill + 50 * rand_range(0,50)
			stats.block = skill + 50 * rand_range(0,50)
			stats.set = skill + 50 * rand_range(0,50)
			stats.spike = skill + 50 * rand_range(0,50)
			stats.verticalJump = rand_range(.5,1.5)
			stats.height = rand_range(1.5,2.3)
			stats.speed = 5
			#//1.25 is the arm factor of newWoman
			stats.spikeHeight = stats.height * (1.33) + stats.verticalJump
			stats.blockHeight = stats.height * (1.25) + stats.verticalJump
			stats.setHeight = stats.height + 0.2
			#stats.shirtNumber = shirtNumbers[j];
			#stats.image = images[j];
			team.allPlayers.append(stats);
			nationalTeam.players.Add(stats);
			#DateTime oldest = new DateTime(1975, 1, 1);

			#int daysRange = (DateTime.Today.AddYears(-17) - oldest).Days;
			#stats.dob = oldest.AddDays( r.Next(daysRange));

			#team.CalculateMacroStats();

			league.clubTeams.Add(team);
#nationalTeam.CalculateMacroStats();
func _init(nam, _pop):
	countryName = nam
	population = _pop
