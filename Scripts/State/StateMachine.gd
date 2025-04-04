extends RefCounted

class_name StateMachine

var entity
var currentState:State
var previousState:State
var queuedState:State
var isStateLocked:bool = false

func _init(_entity):
	entity = _entity

func SetCurrentState(newState:State):
	if isStateLocked:
		queuedState = newState
		return

	if currentState:
		previousState = currentState
		previousState.Exit(entity)

	currentState = newState
	currentState.Enter(entity)

func Update():
	currentState.Update(entity)

func RevertToPreviousState():
	SetCurrentState(entity)
