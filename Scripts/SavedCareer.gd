class_name SavedCareer
extends Resource

@export var path:String = "res://save_test.tres"

#@export var inGameUnixTime:int
@export var cash:int
@export var gameWorld:GameWorld

#Can't have circular refs, need to store the index in gameWorld...
@export var myTeamChoiceState:PlayerChoiceState
@export var isClubOrInternational:Enums.ClubOrInternational

@export var number:int = 0
@export var string = "blah"


func SaveGame():
	ResourceSaver.save(self, path, ResourceSaver.FLAG_NONE)
	pass

static func LoadGame(_path:String) -> Resource:
	if ResourceLoader.exists(_path):
		return ResourceLoader.load(_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return null
