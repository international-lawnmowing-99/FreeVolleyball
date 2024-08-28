extends Control

var gameWorld:GameWorld


@onready var seasonOverviewBackground = $Background/SeasonOverviewBackground
func _ready():
	if GlobalVariables.savedGam == null:
		print(":(")
		GlobalVariables.savedGam = SavedCareer.LoadGame("res://save_test.tres")


	gameWorld = GlobalVariables.savedGam.gameWorld

	DisplayCurrentTime()

func DisplayCurrentTime():
	var dateDict = Time.get_date_dict_from_unix_time(gameWorld.inGameUnixDate)
	$Background/CurrentDateLabel.text = str(dateDict["day"]) + " - " + str(dateDict["month"]) + " - " + str(dateDict["year"])
