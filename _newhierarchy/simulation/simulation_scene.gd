extends Node2D

func _ready() -> void:
	var team_a := TeamData.new()
	team_a.teamName = "Alpha"
	team_a.Populate(PlayerChoiceState.new(), ["Cameron"], ["Borgas"])
	team_a.courtPlayers = team_a.matchPlayers.slice(0, 6)

	var team_b := TeamData.new()
	team_b.teamName = "Bravo"
	team_b.Populate(PlayerChoiceState.new(), ["Tiglath-Pileser"], ["III"])
	team_b.courtPlayers = team_b.matchPlayers.slice(0, 6)

	var sim := MatchSimulation.new(team_a, team_b)
	var result := sim.play_match()
	print(result)
