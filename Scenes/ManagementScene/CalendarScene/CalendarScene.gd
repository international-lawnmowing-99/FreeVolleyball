extends Control

var gameWorld:GameWorld
var listOfTournamentsToDisplay:Array[Tournament] = []
var tournamentDisplayRect:PackedScene = load("res://Scenes/ManagementScene/CalendarScene/TournamentDisplayRect.tscn")
@onready var seasonOverviewBackground = $Background/SeasonOverviewBackground
func _ready():
	if GlobalVariables.savedGam == null:
		print(":(")
		GlobalVariables.savedGam = SavedCareer.LoadGame("res://save_test.tres")


	gameWorld = GlobalVariables.savedGam.gameWorld
	gameWorld.inGameUnixDate += 24*60*60*45235
	DisplayTournament(Tournament.new())
	DisplayCurrentTime()
	GenerateWeekLinesOnCalendar()

func DisplayCurrentTime():
	var dateDict = Time.get_date_dict_from_unix_time(gameWorld.inGameUnixDate)
	$Background/CurrentDateLabel.text = str(dateDict["day"]) + " - " + str(dateDict["month"]) + " - " + str(dateDict["year"])


func GenerateWeekLinesOnCalendar():
	var weekLines:VBoxContainer = $Background/SeasonOverviewBackground/WeekLines
	var currentYear = Time.get_date_dict_from_unix_time(gameWorld.inGameUnixDate)["year"]

	var unixTimeStep = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":1, "day":1})
	var dayOfWeekOfFirstDayOfYear:int = Time.get_date_dict_from_unix_time(unixTimeStep)["weekday"]
	Console.AddNewLine("First day of the week is: " + str(dayOfWeekOfFirstDayOfYear))

	# make it always start on a Sunday
	if dayOfWeekOfFirstDayOfYear == 0:
		pass
	else:
		unixTimeStep -= 24*60*60*dayOfWeekOfFirstDayOfYear

	for i in range(53):
		var startDay = str(Time.get_date_dict_from_unix_time(unixTimeStep)["day"])
		var startMonth = str(Time.get_date_dict_from_unix_time(unixTimeStep)["month"])
		unixTimeStep += 24*60*60*7
		var endDay = str(Time.get_date_dict_from_unix_time(unixTimeStep)["day"] - 1)
		var endMonth = str(Time.get_date_dict_from_unix_time(unixTimeStep)["month"])
		weekLines.get_child(i).get_child(0).text = startDay + "/" + startMonth + " to " + endDay + "/" + endMonth
		pass

func DisplayTournament(_tournament:Tournament):

	var newRect:ColorRect = tournamentDisplayRect.instantiate()
	newRect.size.y = 100
	newRect.get_child(0).size.y = 100

	seasonOverviewBackground.add_child(newRect)

	newRect.position.x = 200

