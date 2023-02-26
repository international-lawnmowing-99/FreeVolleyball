# Licensed under the MIT License.
# Copyright (c) 2018-2020 Jaccomo Lorenz (Maujoe)

extends Node3D

# User settings:
# General settings
@export var enabled = true : set = set_enabled

# See https://docs.godotengine.org/en/latest/classes/class_input.html?highlight=Input#enumerations
@export var mouse_mode = Input.MOUSE_MODE_CAPTURED # (int, "Visible", "Hidden", "Captured, Confined")

enum Freelook_Modes {MOUSE, INPUT_ACTION, MOUSE_AND_INPUT_ACTION}

# Freelook settings
@export var freelook = true
@export var freelook_mode:Freelook_Modes = Freelook_Modes.MOUSE_AND_INPUT_ACTION
@export var sensitivity:float = 0.5
@export var smoothness = 0.5 : set = set_smoothness
@export var yaw_limit = 360
@export var pitch_limit = 360

# Pivot Settings
@export var pivotPath: NodePath : set = set_pivot
var pivot
@export var distance = 5.0 : set = set_distance
@export var rotate_pivot = false
@export var collisions = true : set = set_collisions

# Movement settings
@export var movement = true
@export var acceleration:float = 1.0
@export var deceleration:float = 0.1
@export var max_speed = Vector3(1.0, 1.0, 1.0)
@export var local = true

# Input Actions
@export var rotate_left_action = "ui_rotate_left"
@export var rotate_right_action = "ui_rotate_right"
@export var rotate_up_action = "ui_rotate_up"
@export var rotate_down_action = "ui_rotate_down"
@export var forward_action = "ui_up"
@export var backward_action = "ui_down"
@export var left_action = "ui_left"
@export var right_action = "ui_right"
@export var up_action = "ui_page_up"
@export var down_action = "ui_page_down"
@export var trigger_action = ""

# Gui settings
@export var use_gui = true
@export var gui_action = "ui_cancel"

# Intern variables.
var _mouse_offset = Vector2()
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)
var _gui

var _triggered=false

const ROTATION_MULTIPLIER = 500

func _ready():
	_check_actions([
		forward_action,
		backward_action,
		left_action,
		right_action,
		gui_action,
		up_action,
		down_action,
		rotate_left_action,
		rotate_right_action,
		rotate_up_action,
		rotate_down_action
	])

	if pivotPath:
		pivot = get_node(pivotPath)
	else:
		pivot = null

	set_enabled(enabled)

	if use_gui:
		_gui = preload("res://Scripts/MatchScene/camera_control_gui.gd")
		_gui = _gui.new(self, gui_action)
		add_child(_gui)

func _input(event):
		if len(trigger_action)!=0:
			if event.is_action_pressed(trigger_action):
				_triggered=true
			elif event.is_action_released(trigger_action):
				_triggered=false
		else:
			_triggered=true
		if freelook and _triggered:
			if event is InputEventMouseMotion:
				_mouse_offset = event.relative
				
			_rotation_offset.x = Input.get_action_strength(rotate_right_action) - Input.get_action_strength(rotate_left_action)
			_rotation_offset.y = Input.get_action_strength(rotate_down_action) - Input.get_action_strength(rotate_up_action)
	
		if movement and _triggered:
			_direction.x = Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
			_direction.y = Input.get_action_strength(up_action) - Input.get_action_strength(down_action)
			_direction.z = Input.get_action_strength(backward_action) - Input.get_action_strength(forward_action)

func _process(delta):
	if _triggered:
		_update_views(delta)

func _update_views(delta):
	if pivot:
		_update_distance()
	if freelook:
		_update_rotation(delta)
	if movement:
		_update_movement(delta)

func _physics_process(delta):
	if _triggered:
		_update_views_physics(delta)

func _update_views_physics(delta):
	# Called when collision are enabled
	_update_distance()
	if freelook:
		_update_rotation(delta)

	var space_state = get_world_3d().get_direct_space_state()
	var obstacle = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pivot.get_position(),  get_position()))
	if not obstacle.is_empty():
		set_position(obstacle.position)

func _update_movement(delta):
	var offset = max_speed * acceleration * _direction

	_speed.x = clamp(_speed.x + offset.x, -max_speed.x, max_speed.x)
	_speed.y = clamp(_speed.y + offset.y, -max_speed.y, max_speed.y)
	_speed.z = clamp(_speed.z + offset.z, -max_speed.z, max_speed.z)

	# Apply deceleration if no input
	if _direction.x == 0:
		_speed.x *= (1.0 - deceleration)
	if _direction.y == 0:
		_speed.y *= (1.0 - deceleration)
	if _direction.z == 0:
		_speed.z *= (1.0 - deceleration)

	if local:
		translate(_speed * delta)
	else:
		global_translate(_speed * delta)

func _update_rotation(delta):
	var offset = Vector2()
	
	if not freelook_mode == Freelook_Modes.INPUT_ACTION:
		offset += _mouse_offset * sensitivity
	if not freelook_mode == Freelook_Modes.MOUSE: 
		offset += _rotation_offset * sensitivity * ROTATION_MULTIPLIER * delta
	
	_mouse_offset = Vector2()

	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + offset.y * (1.0 - smoothness)

	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)

	_total_yaw += _yaw
	_total_pitch += _pitch

	if pivot:
		var target = pivot.get_position()
		var dist = get_position().distance_to(target)

		set_position(target)
		rotate_y(deg_to_rad(-_yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-_pitch))
		translate(Vector3(0.0, 0.0, dist))

		if rotate_pivot:
			pivot.rotate_y(deg_to_rad(-_yaw))
	else:
		rotate_y(deg_to_rad(-_yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-_pitch))

func _update_distance():
	var t = pivot.get_position()
	t.z -= distance
	set_position(t)

func _update_process_func():
	# Use physics process if collision are enabled
	if collisions and pivot:
		set_physics_process(true)
		set_process(false)
	else:
		set_physics_process(false)
		set_process(true)

func _check_actions(actions=[]):
	if OS.is_debug_build():
		for action in actions:
			if not InputMap.has_action(action):
				print('WARNING: No action "' + action + '"')

func set_pivot(value):
	pivot = value
	_update_process_func()
	if len(trigger_action)!=0:
		_update_views(0)

func set_collisions(value):
	collisions = value
	_update_process_func()

func set_enabled(value):
	enabled = value
	if enabled:
		Input.set_mouse_mode(mouse_mode)
		set_process_input(true)
		_update_process_func()
	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

func set_smoothness(value):
	smoothness = clamp(value, 0.001, 0.999)

func set_distance(value):
	distance = max(0, value)
