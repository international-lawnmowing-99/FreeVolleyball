extends CanvasLayer
class_name ServeUI

@onready var serverNameLabel:Label = $ServerInfo/ServerNameLabel
@onready var jumpServeLabel:Label = $ServerInfo/JumpServeLabel
@onready var floatServeLabel:Label = $ServerInfo/FloatServeLabel

enum UIState{
	UNDEFINED,
	ServeType,
	ServeAggression
}

var humanServeState:AthleteHumanServeState
var uiState = UIState.UNDEFINED

func ShowServeChoice():
	$ServeTypeButtons.show()
	$ServerInfo.show()
	UpdateServerInfo(humanServeState._athlete)
	uiState = UIState.ServeType
	$RememberServeOptions.show()
	$RememberServeOptions/CheckBox.button_pressed = humanServeState.rememberSettings
	if !ValidLastServeOption():
		$RememberServeOptions/RepeatLastServe.hide()
	else:
		$RememberServeOptions/RepeatLastServe.show()

func HideServeChoice():
	$ServeTypeButtons.hide()
	$ServerInfo.hide()
	$RememberServeOptions.hide()
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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Key4"):
		_on_RepeatLastServe_pressed()
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


func _on_CheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		# Settings will be remembered
		humanServeState.rememberSettings = true

	else:
		humanServeState.rememberSettings = false


func _on_RepeatLastServe_pressed() -> void:
	if humanServeState && ValidLastServeOption():
		humanServeState.serveTarget.position = humanServeState.rememberedServeTarget
		humanServeState.serveType = humanServeState.rememberedServeType
		humanServeState.ChooseServeType(humanServeState.rememberedServeType)
		humanServeState.serveAggression = humanServeState.rememberedServeAggression
		humanServeState.ChooseServeAggression(humanServeState.rememberedServeAggression)
		humanServeState._athlete.position = humanServeState.rememberedWalkPosition
		humanServeState.CommenceServe()

func ValidLastServeOption():
	if !humanServeState.rememberSettings || humanServeState.rememberedServeTarget == null || humanServeState.rememberedServeType == null || humanServeState.rememberedServeAggression == null || humanServeState.rememberedWalkPosition == null:
		return false
	if !(humanServeState.serveState == humanServeState.ServeState.Walking):
		return false
	return true

func UpdateServerInfo(athlete:Athlete):
	serverNameLabel.text = athlete.stats.firstName + " " + athlete.stats.lastName
	jumpServeLabel.text = "Jump Serve: " + str("%.1f" % athlete.stats.serve)
	floatServeLabel.text = "Float Serve: " + str("%.1f" % athlete.stats.floatServe)
