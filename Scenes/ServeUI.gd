extends CanvasLayer

enum UIState{
	UNDEFINED,
	ServeType,
	ServeAggression
}

var humanServeState
var uiState = UIState.UNDEFINED

func ShowServeChoice():
	$ServeTypeButtons.show()
	$ServerInfo.show()
	uiState = UIState.ServeType

func HideServeChoice():
	$ServeTypeButtons.hide()
	$ServerInfo.hide()
	uiState = UIState.UNDEFINED
	
func ShowServeAggressionChoice():
	$ServeAggressionButtons.show()
	uiState = UIState.ServeAggression

func HideServeAggressionChoice():
	$ServeAggressionButtons.hide()
	uiState = UIState.UNDEFINED

func _on_UnderArmButton_pressed():
	humanServeState.ChooseServeType(humanServeState.ServeType.Underarm)
	HideServeChoice()
	ShowServeAggressionChoice()

func _on_JumpServeButton_pressed():
	humanServeState.ChooseServeType(humanServeState.ServeType.Jump)
	HideServeChoice()
	ShowServeAggressionChoice()

func _on_FloatButton_pressed():
	humanServeState.ChooseServeType(humanServeState.ServeType.Float)
	HideServeChoice()
	ShowServeAggressionChoice()


func _on_AggressiveServe_pressed() -> void:
	humanServeState.ChooseServeAggression(humanServeState.ServeAggression.Aggressive)
	HideServeAggressionChoice()

func _on_SafetyServe_pressed() -> void:
	humanServeState.ChooseServeAggression(humanServeState.ServeAggression.Safety)
	HideServeAggressionChoice()

func _on_ModerateServe_pressed() -> void:
	humanServeState.ChooseServeAggression(humanServeState.ServeAggression.Moderate)
	HideServeAggressionChoice()

func _process(delta: float) -> void:
	match uiState:
		UIState.ServeType:
			if Input.is_action_just_pressed("Key1"):
				_on_JumpServeButton_pressed()
			elif Input.is_action_just_pressed("Key2"):
				_on_FloatButton_pressed()
			elif Input.is_action_just_pressed("Key3"):
				_on_UnderArmButton_pressed()
		UIState.ServeAggression:
			if Input.is_action_just_pressed("Key1"):
				_on_AggressiveServe_pressed()
			elif Input.is_action_just_pressed("Key2"):
				_on_ModerateServe_pressed()
			elif Input.is_action_just_pressed("Key3"):
				_on_SafetyServe_pressed()
