class_name SavedCareer
extends Resource

@export var path:String = "res://save_test.tres"

@export var inGameUnixTime:int

@export var gameWorld:GameWorld

@export var number:int = 0
@export var string = "blah"


func SaveGame():
	ResourceSaver.save(self, path, ResourceSaver.FLAG_NONE)
	pass

func LoadGame(_path = path) -> Resource:
	if ResourceLoader.exists(_path):
		return ResourceLoader.load(_path)
	return null
