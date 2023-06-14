extends TextureRect
class_name ReceiverRepresentationUI

var receiveOptionsUI:ReceiveOptionsUI
var rotationPosition:int
var bounds
var selected:bool = false
var selectable:bool = true
var lerpSpeed = 10
var athlete:Athlete

var offsetY
var offsetX
var halfCourtOffsetX
var halfCourtOffsetY

func _process(delta):
	if selected:
		# global position x is left-right on the screen, but my x is towards-away from net
		position.x = lerp(position.x, get_global_mouse_position().x - halfCourtOffsetX - offsetX, delta * lerpSpeed)
		position.x = clamp(position.x, bounds[2], bounds[3] - 2 * offsetX)
		position.y = lerp(position.y, get_global_mouse_position().y - halfCourtOffsetY - offsetY, delta * lerpSpeed)
		position.y = clamp(position.y, bounds[0], bounds[1] - 2 * offsetY)

func _on_button_toggled(_button_pressed):
	if selectable:
		selected = !selected
		
		if selected:
			receiveOptionsUI.LockReceiverUI(self)
			self_modulate = Color.BLUE
		else:
			receiveOptionsUI.UnlockReceiverUI(self)
			self_modulate = Color.WHITE
