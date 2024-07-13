extends Control

@onready var simulatingPopup:PopupPanel = $SimulatingPopup
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_next_match_button_pressed():
	simulatingPopup.popup()
	FreezeControls()
	Thread
	#Surely there has to be a better way, but as it stands the function completes entirely before showing the popup
	await get_tree().create_timer(0.1).timeout
	SimulateDay()
	simulatingPopup.hide()
	UnfreezeControls()

func _on_next_day_button_pressed():
	pass # Replace with function body.

func SimulateDay():
	for i in 499999:
		print(str(sqrt(i)))



func FreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = true
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = true
func UnfreezeControls():
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextDayButton.disabled = false
	$Background/VBoxContainer/TricolourContainer/Column3/CalendarManagementScene/NextMatchButton.disabled = false
