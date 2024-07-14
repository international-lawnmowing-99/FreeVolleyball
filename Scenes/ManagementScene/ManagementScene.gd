extends Control

@onready var simulatingPopup:PopupPanel = $SimulatingPopup
# Called when the node enters the scene tree for the first time.

var unixTime:int

func _ready():
	unixTime = Time.get_unix_time_from_datetime_string("2025-01-01")

func _on_next_match_button_pressed():
	simulatingPopup.popup()
	FreezeControls()
	#Thread???
	#Surely there has to be a better way, but as it stands the function completes entirely before showing the popup
	await get_tree().create_timer(0.1).timeout
	SimulateDay()
	simulatingPopup.hide()
	UnfreezeControls()

func _on_next_day_button_pressed():
	SimulateDay()
	pass # Replace with function body.

func SimulateDay():
	print("Previous day was " +str(Time.get_date_dict_from_unix_time(unixTime)))
	unixTime += 24*60*60

	print("New day is " + str(Time.get_date_dict_from_unix_time(unixTime)))


func FreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = true
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = true
func UnfreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = false
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = false
