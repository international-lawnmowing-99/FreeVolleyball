extends "res://Scripts/Team.gd"

func _ready():
	pass 

func _process(delta):
	if !isNextToAttack && (mManager.gameState == mManager.GameState.Set || mManager.gameState == mManager.GameState.Spike || mManager.gameState == mManager.GameState.Receive):
		GetBlockInput()
	if isNextToAttack && (mManager.gameState == mManager.GameState.Receive || mManager.gameState == mManager.GameState.Set):
		ChoosePlay()

func GetBlockInput():
	pass
	
func ChoosePlay():
	pass
