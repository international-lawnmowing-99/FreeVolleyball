class_name SimulationEventLog
extends RefCounted

enum Verbosity {
	BASIC,
	INTERMEDIATE,
	VERBOSE
}

var verbosity: int = Verbosity.BASIC
var entries: Array[Dictionary] = []

func configure(new_verbosity: int) -> void:
	verbosity = new_verbosity

func log(phase: String, message: String, team: TeamData = null, athlete: AthleteStats = null, required_verbosity: int = Verbosity.BASIC) -> void:
	var team_name := "N/A"
	var athlete_name := "N/A"
	if team != null:
		team_name = team.teamName
	if athlete != null:
		athlete_name = "%s %s" % [athlete.firstName, athlete.lastName]

	var formatted := "[Sim][%s] %s | Team=%s | Player=%s" % [phase, message, team_name, athlete_name]
	entries.append({
		"phase": phase,
		"message": formatted,
		"team": team,
		"athlete": athlete,
		"verbosity": required_verbosity
	})

	if required_verbosity > verbosity:
		return

	print(formatted)
