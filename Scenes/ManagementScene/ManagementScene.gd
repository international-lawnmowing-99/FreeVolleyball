extends Control

var savedCareer:SavedCareer
@onready var simulatingPopup:PopupPanel = $SimulatingPopup
@onready var calendarButton = $MarginContainer/VBoxContainer/BasicInfo/CalendarButton





func _ready():
	if GlobalVariables.savedGam == null:
		print(":(")
		GlobalVariables.savedGam = SavedCareer.LoadGame("res://save_test.tres")


	savedCareer = GlobalVariables.savedGam
	calendarButton.text =  unix_to_ddmmyyyy(savedCareer.gameWorld.inGameUnixDate)
	$Background/VBoxContainer/TeamNameBackground/TeamNameLabel.text = savedCareer.gameWorld.GetTeam(savedCareer.myTeamChoiceState, savedCareer.isClubOrInternational).teamName

func unix_to_ddmmyyyy(unix_time: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d" % [dt.day, dt.month, dt.year]

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

func SimulateDay():
	savedCareer.gameWorld.SimulateDay()
	Console.AddNewLine("Previous day was " +str(Time.get_date_dict_from_unix_time(savedCareer.gameWorld.inGameUnixDate)))
	savedCareer.gameWorld.inGameUnixDate += 24*60*60
	calendarButton.text =  unix_to_ddmmyyyy(savedCareer.gameWorld.inGameUnixDate)

	Console.AddNewLine("New day is " + str(Time.get_date_dict_from_unix_time(savedCareer.gameWorld.inGameUnixDate)))


func FreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = true
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = true
func UnfreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = false
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = false


func _on_calendar_button_pressed() -> void:
	$CalendarStandard.show()
	pass # Replace with function body.
