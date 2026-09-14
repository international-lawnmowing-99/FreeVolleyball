extends Resource
class_name RoleTacticalSystem

## Team-system positioning data interpreted with role responsibilities. It is
## deliberately separate from PlayerRoleDefinition so the same role can be
## combined with different systems.
@export var setter_target: Vector3 = Vector3(0.85, 0.0, 0.0)
@export var second_ball_preparation_target: Vector3 = Vector3(1.25, 0.0, 0.0)
@export var attack_front_targets := {
	PlayerRoleDefinition.Lane.LEFT: Vector3(1.45, 0.0, 3.35),
	PlayerRoleDefinition.Lane.MIDDLE: Vector3(1.45, 0.0, 0.0),
	PlayerRoleDefinition.Lane.RIGHT: Vector3(1.45, 0.0, -3.35)
}
@export var attack_back_targets := {
	PlayerRoleDefinition.Lane.LEFT: Vector3(3.0, 0.0, 3.35),
	PlayerRoleDefinition.Lane.MIDDLE: Vector3(3.0, 0.0, 0.0),
	PlayerRoleDefinition.Lane.RIGHT: Vector3(3.0, 0.0, -3.35)
}
@export var block_targets := {
	PlayerRoleDefinition.Lane.LEFT: Vector3(0.25, 0.0, 3.35),
	PlayerRoleDefinition.Lane.MIDDLE: Vector3(0.25, 0.0, 0.0),
	PlayerRoleDefinition.Lane.RIGHT: Vector3(0.25, 0.0, -3.35)
}
@export var defence_targets := {
	PlayerRoleDefinition.DefensiveSlot.LEFT: Vector3(3.55, 0.0, 3.35),
	PlayerRoleDefinition.DefensiveSlot.MIDDLE: Vector3(3.55, 0.0, 0.0),
	PlayerRoleDefinition.DefensiveSlot.RIGHT: Vector3(3.55, 0.0, -3.35)
}
