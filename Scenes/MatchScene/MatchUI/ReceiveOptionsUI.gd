extends Control
class_name ReceiveOptionsUI

@onready var courtRepresentationReceive = $CourtRepresentationUI
@onready var displayedRotationLabel = $DisplayedRotationLabel
var teamA:Team
var teamB:Team

var pseudoTeam = PseudoTeam.new()

#[minX, maxX, minZ, maxZ]
# X is distance from the net (0-9), Z is (-4.5 - 4.5)
var position1Bounds = [0,0,0,0]
var position2Bounds = [0,0,0,0]
var position3Bounds = [0,0,0,0]
var position4Bounds = [0,0,0,0]
var position5Bounds = [0,0,0,0]
var position6Bounds = [0,0,0,0]

var currentRotationPositions

var scalingFactorX
var scalingFactorY 
var offsetX
var offsetY

@onready var receiverUIArray = $HalfCourtRepresentationUI/ValuedTeamMembers.get_children()

func Init():
	scalingFactorX = 909/9 # where does the 9 come from? 909 is court size... (never mind, it's the ration of pixel court size to metres physical court size)
	scalingFactorY = 909/9
	offsetX = receiverUIArray[0].size.x/2 * receiverUIArray[0].scale.x
	offsetY = receiverUIArray[0].size.y/2 * receiverUIArray[0].scale.y
	
	pseudoTeam.CopyTeam(teamA)
	var i = 0
	for receiverUI in receiverUIArray:
		receiverUI.receiveOptionsUI = self
		receiverUI.halfCourtOffsetX = $HalfCourtRepresentationUI/ValuedTeamMembers.global_position.x
		receiverUI.halfCourtOffsetY = $HalfCourtRepresentationUI/ValuedTeamMembers.global_position.y
		receiverUI.offsetY = offsetY
		receiverUI.offsetX = offsetX
		
func _on_rot_1_button_pressed():
	DisplayRotation(1)


func _on_rot_2_button_pressed():
	DisplayRotation(2)


func _on_rot_3_button_pressed():
	DisplayRotation(3)


func _on_rot_4_button_pressed():
	DisplayRotation(4)


func _on_rot_5_button_pressed():
	DisplayRotation(5)


func _on_rot_6_button_pressed():
	DisplayRotation(6)

func DisplayRotation(positionOfOriginalRot1Player:int):
	displayedRotationLabel.text = "Rotation " + str(positionOfOriginalRot1Player)
	var rotationDifference = pseudoTeam.originalRotation1Player.pseudoRotationPosition - positionOfOriginalRot1Player
	if rotationDifference < 0:
		rotationDifference = 6 + rotationDifference
	
	for i in range(rotationDifference):
		pseudoTeam.PseudoRotate()
	
	var i = 0
	for athlete in pseudoTeam.courtPlayers:
		var rect = $HalfCourtRepresentationUI/ValuedTeamMembers.get_child(i)
		var pos = teamA.defaultReceiveRotations[pseudoTeam.server][athlete.pseudoRotationPosition - 1]
		rect.get_node("Name").text = athlete.stats.lastName + ": " + str(athlete.pseudoRotationPosition)
		rect.position.x = scalingFactorX * -pos.z - offsetX
		rect.position.y = scalingFactorY * pos.x - offsetY
		i += 1
		rect.athlete = athlete
	
	currentRotationPositions = teamA.defaultReceiveRotations[pseudoTeam.server]

func LockReceiverUI(selectedReceiver:ReceiverRepresentationUI):
	for lad in receiverUIArray:
		if lad != selectedReceiver:
			lad.selectable = false
			
	UpdateBounds()
	var myBounds
	match selectedReceiver.athlete.pseudoRotationPosition:
		1: myBounds = position1Bounds
		2: myBounds = position2Bounds
		3: myBounds = position3Bounds
		4: myBounds = position4Bounds
		5: myBounds = position5Bounds
		6: myBounds = position6Bounds
		
	# warning, inconsistent offsets incoming...
	myBounds[0] = myBounds[0] * scalingFactorY #+ offsetY
	myBounds[1] = myBounds[1] * scalingFactorY #+ offsetY
	myBounds[2] = myBounds[2] * scalingFactorX# + offsetX
	myBounds[3] = myBounds[3] * scalingFactorX# + offsetX
	
	selectedReceiver.bounds = myBounds
	
	Console.AddNewLine(str(myBounds))
	var lineThicknessHalf = 2.5
	$HalfCourtRepresentationUI/Bounds/XMinBoundsLine2D.position.y = myBounds[0] - lineThicknessHalf
	$HalfCourtRepresentationUI/Bounds/XMaxBoundsLine2D.position.y = myBounds[1] - lineThicknessHalf 
	$HalfCourtRepresentationUI/Bounds/ZMinBoundsLine2D.position.x = myBounds[2] - lineThicknessHalf
	$HalfCourtRepresentationUI/Bounds/ZMaxBoundsLine2D.position.x = myBounds[3] - lineThicknessHalf
func UnlockReceiverUI():
	for lad in receiverUIArray:
		lad.selectable = true
	
	#!!!!!!!!!!!!!!!!!!
	#currentRotationPositions Updated

func _on_current_rotation_button_pressed():
	DisplayRotation(teamA.originalRotation1Player.rotationPosition)
	displayedRotationLabel.text = "Rotation " + str(teamA.originalRotation1Player.rotationPosition)

func UpdateBounds():
	position1Bounds[0] = currentRotationPositions[1].x
	position1Bounds[1] = 9
	position1Bounds[2] = currentRotationPositions[5].z
	position1Bounds[3] = 4.5

	position2Bounds[0] = 0
	position2Bounds[1] = currentRotationPositions[0].x
	position2Bounds[2] = -currentRotationPositions[2].z
	position2Bounds[3] = 4.5
	
	position3Bounds[0] = 0
	position3Bounds[1] = currentRotationPositions[5].x
	position3Bounds[2] = -currentRotationPositions[3].z
	position3Bounds[3] = -currentRotationPositions[1].z
	
	position4Bounds[0] = 0
	position4Bounds[1] = currentRotationPositions[4].x
	position4Bounds[2] = -4.5
	position4Bounds[3] = -currentRotationPositions[2].z
	
	position5Bounds[0] = currentRotationPositions[3].x
	position5Bounds[1] = 9
	position5Bounds[2] = -4.5
	position5Bounds[3] = -currentRotationPositions[5].z
	
	position6Bounds[0] = currentRotationPositions[2].x
	position6Bounds[1] = 9
	position6Bounds[2] = -currentRotationPositions[4].z
	position6Bounds[3] = -currentRotationPositions[0].z
