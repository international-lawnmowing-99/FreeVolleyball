extends Spatial
const Enums = preload("res://Scripts/World/Enums.gd")

var camera
var text:RichTextLabel
var athlete:Athlete
func _ready():
	camera = get_node("/root/MatchScene/Camera")
	text = $RichTextLabel
	athlete = $"../../"
	text.text = athlete.stats.lastName

	
func _process(delta):
	var screen_pos = camera.unproject_position(global_transform.origin)
	text.set_position(screen_pos+Vector2.ONE)
	if !athlete.team.isHuman:
		text.set("custom_colors/default_color",Color(1,1,0))
	if athlete.role && athlete.stateMachine.currentState: 
		text.text = athlete.stats.lastName + " " +  str(athlete.rotationPosition) + "\n"  +\
		"role: " + Enums.Role.keys()[athlete.role] + "\n" + \
		"state: " + str(athlete.stateMachine.currentState.nameOfState)
		if athlete.stateMachine.currentState == athlete.spikeState:
			text.text += "\n" + athlete.spikeState.SpikeState.keys()[athlete.spikeState.spikeState]
		if athlete.stateMachine.currentState == athlete.blockState:
			text.text += "\n" + athlete.blockState.BlockState.keys()[athlete.blockState.blockState]

	
