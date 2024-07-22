extends Control

@onready var simulatingPopup:PopupPanel = $SimulatingPopup
# Called when the node enters the scene tree for the first time.
var savedCareer:SavedCareer



func _ready():
	if GlobalVariables.savedGam == null:
		print(":(")
		GlobalVariables.savedGam = SavedCareer.LoadGame("res://save_test.tres")


	savedCareer = GlobalVariables.savedGam

	$Background/VBoxContainer/TeamNameBackground/TeamNameLabel.text = savedCareer.gameWorld.GetTeam(savedCareer.myTeamChoiceState, savedCareer.isClubOrInternational).teamName


func _on_next_match_button_pressed():
	simulatingPopup.popup()
	FreezeControls()
	#Thread???
	#Surely there has to be a better way, but as it stands the function completes entirely before showing the popup
	await get_tree().create_timer(0.05).timeout
	SimulateDay()
	simulatingPopup.hide()
	UnfreezeControls()

func _on_next_day_button_pressed():
	SimulateDay()
	pass # Replace with function body.

func SimulateDay():
	savedCareer.gameWorld.SimulateDay()
	Console.AddNewLine("Previous day was " +str(Time.get_date_dict_from_unix_time(savedCareer.gameWorld.inGameUnixDate)))
	savedCareer.gameWorld.inGameUnixDate += 24*60*60

	Console.AddNewLine("New day is " + str(Time.get_date_dict_from_unix_time(savedCareer.gameWorld.inGameUnixDate)))


func FreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = true
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = true
func UnfreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = false
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = false
