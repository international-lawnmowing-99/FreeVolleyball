extends "res://Scripts/Team.gd"
class_name HumanTeam

signal teamABallOverNet

func _process(delta):
	return
#	if !isNextToAttack && (mManager.gameState == mManager.GameState.Set || mManager.gameState == mManager.GameState.Spike || mManager.gameState == mManager.GameState.Receive):
#		GetBlockInput()
#	if isNextToAttack && (mManager.gameState == mManager.GameState.Receive || mManager.gameState == mManager.GameState.Set):
#		ChoosePlay()
	._process(delta)

func GetBlockInput():
	pass
	
func ChoosePlay():
	pass



