extends ColorRect

var tournamentDisplayRect:PackedScene = load("res://Scenes/ManagementScene/CalendarScene/TournamentDisplayRect.tscn")
var listOfTournamentsToDisplay:Array[Tournament] = []
var gameWorld:GameWorld
@onready var weekLinesHolder:VBoxContainer = $WeekLines
var weekLinesArray:Array[WeekLine] = []

func _ready():
	if GlobalVariables.savedGam == null:
		print("Season overview loaded it")
		GlobalVariables.savedGam = SavedCareer.LoadGame("res://save_test.tres")


	gameWorld = GlobalVariables.savedGam.gameWorld
	gameWorld.inGameUnixDate += 24*60*60* randi_range(13235, 55235)

	var vnl = Tournament.new()
	vnl.tournamentName = "VNL"
	vnl.mainColour = Color.CRIMSON
	var currentYear = Time.get_date_dict_from_unix_time(gameWorld.inGameUnixDate)["year"]
	vnl.startDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":8, "day":1})

	var clubSeason = Tournament.new()
	clubSeason.tournamentName = "Club Season " + str(currentYear - 1) + "/" + str(currentYear)
	clubSeason.mainColour = Color.DARK_GRAY
	clubSeason.startDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear - 1, "month":10, "day":13})
	clubSeason.endDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":5, "day":15})

	var clubSeason2 = Tournament.new()
	clubSeason2.tournamentName = "Club Season " + str(currentYear) + "/" + str(currentYear + 1)
	clubSeason2.mainColour = Color.WEB_GRAY
	clubSeason2.startDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":10, "day":19})
	clubSeason2.endDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear + 1, "month":5, "day":15})

	var clubWorldChamps = Tournament.new()
	clubWorldChamps.tournamentName = "Club WCH"
	clubWorldChamps.mainColour = Color.DARK_RED
	clubWorldChamps.startDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":12, "day":8})
	clubWorldChamps.endDateUnix = Time.get_unix_time_from_datetime_dict({"year":currentYear, "month":12, "day":9})


	GenerateWeekLinesOnCalendar()
	await get_tree().process_frame
	DisplayTournament(vnl)
	DisplayTournament(clubSeason)
	DisplayTournament(clubSeason2)
	DisplayTournament(clubWorldChamps)

func GenerateWeekLinesOnCalendar():
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
		var weekLine:WeekLine = weekLinesHolder.get_child(i)

		weekLine.startDateUnix = unixTimeStep

		var startDay = str(Time.get_date_dict_from_unix_time(unixTimeStep)["day"])
		var startMonth = str(Time.get_date_dict_from_unix_time(unixTimeStep)["month"])
		unixTimeStep += 24*60*60*7

		weekLine.endDateUnix = unixTimeStep

		var endDay = str(Time.get_date_dict_from_unix_time(unixTimeStep - 24*3600)["day"])
		var endMonth = str(Time.get_date_dict_from_unix_time(unixTimeStep - 24*3600)["month"])
		weekLine.get_child(0).text = startDay + "/" + startMonth + " to " + endDay + "/" + endMonth

		weekLinesArray.append(weekLine)

func DisplayTournament(_tournament:Tournament):

	var newRect:ColorRect = tournamentDisplayRect.instantiate()
	newRect.color = _tournament.mainColour
	(newRect.get_child(0).get_child(0) as Label).text = _tournament.tournamentName
	newRect.size.y = 100
	newRect.get_child(0).size.y = 100

	add_child(newRect)

	newRect.position.x = 200
	if _tournament.startDateUnix != 0:
		var startWeekLine:WeekLine
		var endWeekLine:WeekLine

		if _tournament.startDateUnix < weekLinesArray[0].startDateUnix:
			#The tournament started last year (or earlier!)
			startWeekLine = weekLinesArray[0]

		if _tournament.endDateUnix >= weekLinesArray[52].endDateUnix:
			#Similarly, it ends next year
			endWeekLine = weekLinesArray[52]

		for week in weekLinesArray:
			if week.startDateUnix <= _tournament.startDateUnix &&\
			week.endDateUnix > _tournament.startDateUnix:
				startWeekLine = week
			if week.startDateUnix <= _tournament.endDateUnix &&\
			week.endDateUnix > _tournament.endDateUnix:
				endWeekLine = week

		if startWeekLine:
			newRect.position.y = startWeekLine.position.y
		if endWeekLine:
			var sizeY = endWeekLine.position.y + endWeekLine.size.y - startWeekLine.position.y
			newRect.size.y = sizeY
			newRect.get_child(0).size.y = sizeY
