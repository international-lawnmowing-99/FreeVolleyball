extends ColorRect
var Enums = preload("res://Scripts/World/Enums.gd")
var isMouseHovering:bool
var cardAthlete:Athlete
var teamSelectionUI
var state = Enums.NameCardState.UNDEFINED
var previousColour:Color

func _ready() -> void:
	ChangeColour(Color.CHOCOLATE)

func DisplayStats(athlete:Athlete):
	cardAthlete = athlete
	$FirstName.text = athlete.stats.firstName
	$LastName.text = athlete.stats.lastName
	var skill = (athlete.stats.set + athlete.stats.spike + athlete.stats.block + athlete.stats.reception)/4
	var skillText = $Skill
	skillText.text = str("%.0f" % skill)
	skillText.add_theme_color_override("font_color",lerp(Color.RED, Color.GREEN, (skill*3-100)/100.0))
#	if skill < 50:
#		skillText.modulate(Color.CRIMSON)
#	elif skill < 60:
#		skillText.modulate(Color.AQUAMARINE)
#	else:
#		skillText.modulate(Color.CHARTREUSE)
	$Height.text = str("%.0f" % (athlete.stats.height *100)) + "cm"
	$Role.text = Enums.Role.keys()[athlete.role]

func DisplayEssentials():
	$LiberoIcon.hide()
	$CaptainIcon.hide()
	$SubstituteButton.hide()
	$CaptainButton.hide()

func ChangeColour(colour = Color(.75,0,0)):
	previousColour = self.color
	self.color = colour


func _on_NameCard_mouse_entered() -> void:
	isMouseHovering = true
	#ChangeColour(Color(0,1,1))
	#selectable = true
	if teamSelectionUI:
		teamSelectionUI.CardSelected(cardAthlete)
	pass # Replace with function body.


func _on_NameCard_mouse_exited() -> void:
	isMouseHovering = false
	#selectable = false
	#ChangeColour(previousColour)
	pass # Replace with function body.


func _on_SubstituteButton_pressed() -> void:
	if teamSelectionUI:
		
		teamSelectionUI.RequestSub(cardAthlete)
		ChangeColour(Color.PURPLE)
	pass # Replace with function body.

func Benched():
	$SubstituteButton.hide()
	$CaptainButton.hide()
	$LiberoIcon.hide()
	$CaptainIcon.hide()



func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("LMB"):
		if state == Enums.NameCardState.Substitutable && isMouseHovering:
			teamSelectionUI.ExecuteSub(cardAthlete)