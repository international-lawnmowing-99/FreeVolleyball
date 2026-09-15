extends Control
class_name SystemEditor

const SystemDefinition = preload("res://_newhierarchy/simulation/system/TeamSystem.gd")
const SystemCatalog = preload("res://_newhierarchy/simulation/system/SystemLibrary.gd")
const Validator = preload("res://_newhierarchy/simulation/system/SystemValidator.gd")
const RoleDefinition = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleDefinition.gd")

const SYSTEM_LIBRARY_PATH := "user://systems.tres"
const ROTATION_POSITIONS := [
	Vector2(0.72, 0.76), Vector2(0.72, 0.25), Vector2(0.50, 0.16),
	Vector2(0.28, 0.25), Vector2(0.28, 0.76), Vector2(0.50, 0.84)
]
const TOUCH_NAMES := ["Pass", "Set", "Attack"]
const ROLE_KEYS := ["receive", "set", "attack", "block", "defend"]

var team: TeamData
var career: SavedCareer
var library
var selected_system: TeamSystem
var draft: TeamSystem
var editing_original: TeamSystem
var default_systems: Array[TeamSystem] = []
var selected_rotation := 1
var editing := false
var role_cards: Array[PanelContainer] = []
var role_controls: Array[Dictionary] = []
var rotation_buttons: Array[Button] = []
var touch_options: Array[OptionButton] = []

@onready var saved_system_list: ItemList = $Margin/Root/Content/Library/SavedSystems
@onready var default_system_list: ItemList = $Margin/Root/Content/Library/DefaultSystems
@onready var system_name: LineEdit = $Margin/Root/Content/Editor/SystemName
@onready var guide_text: TextEdit = $Margin/Root/Content/Editor/Tabs/Guide/GuideText
@onready var first_touch: OptionButton = $Margin/Root/Content/Editor/Tabs/PhaseGoal/Goals/FirstTouch
@onready var second_touch: OptionButton = $Margin/Root/Content/Editor/Tabs/PhaseGoal/Goals/SecondTouch
@onready var third_touch: OptionButton = $Margin/Root/Content/Editor/Tabs/PhaseGoal/Goals/ThirdTouch
@onready var status: Label = $Margin/Root/Header/Status
@onready var editor_tabs: TabContainer = $Margin/Root/Content/Editor/Tabs
@onready var edit_button: Button = $Margin/Root/Content/Library/Edit
@onready var save_button: Button = $Margin/Root/SaveBar/Save
@onready var save_copy_button: Button = $Margin/Root/SaveBar/SaveCopy
@onready var use_button: Button = $Margin/Root/Content/Library/Use
@onready var check_button: Button = $Margin/Root/ValidationBar/Check
@onready var validation_results: RichTextLabel = $Margin/Root/ValidationBar/Results

func _ready() -> void:
	rotation_buttons = [
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation1,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation2,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation3,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation4,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation5,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar/Rotation6
	]
	role_cards = [
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard1,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard2,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard3,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard4,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard5,
		$Margin/Root/Content/Editor/Tabs/PlayerRoles/Court/PlayerCard6
	]
	role_controls = []
	for index in range(6):
		var card := role_cards[index]
		var controls := {
			"receive": card.get_node("Body/Receive"),
			"set": card.get_node("Body/Set"),
			"attack": card.get_node("Body/Attack"),
			"block": card.get_node("Body/Block"),
			"defend": card.get_node("Body/Defend"),
			"backup_setter": card.get_node("Body/BackupSetter"),
			"preparation": card.get_node("Body/Preparation")
		}
		role_controls.append(controls)
		controls["preparation"].add_item("Prepare for next role")
		controls["preparation"].add_item("Chill")
		for key in ROLE_KEYS + ["backup_setter"]:
			controls[key].toggled.connect(_on_role_toggle.bind(index, key))
		controls["preparation"].item_selected.connect(_on_preparation_selected.bind(index))
		card.get_node("Body/PlayerName").text = ["Player A", "Player B", "Player C", "Player D", "Player E", "Player F"][index]
	for option in [first_touch, second_touch, third_touch]:
		option.add_item("Pass")
		option.add_item("Set")
		option.add_item("Attack")
		touch_options.append(option)
		option.item_selected.connect(_on_touch_goal_changed)
	for button in rotation_buttons:
		button.pressed.connect(_on_rotation_pressed.bind(button))
	editor_tabs.tab_changed.connect(_on_tab_changed)
	saved_system_list.item_selected.connect(_on_saved_system_selected)
	default_system_list.item_selected.connect(_on_default_system_selected)
	$Margin/Root/Header/Close.pressed.connect(hide)
	$Margin/Root/Content/Library/New.pressed.connect(_new_system)
	edit_button.pressed.connect(_edit_selected)
	$Margin/Root/Content/Library/Load.pressed.connect(_load_library)
	$Margin/Root/Content/Library/SaveLibrary.pressed.connect(_save_library)
	use_button.pressed.connect(_use_selected)
	save_button.pressed.connect(_save_system)
	save_copy_button.pressed.connect(_save_system_copy)
	check_button.pressed.connect(_check_system)
	_load_library()
	_load_default_systems()
	_set_editing(false)
	call_deferred("_refresh_rotation")

func _on_tab_changed(tab_index: int) -> void:
	if tab_index == 2:
		call_deferred("_refresh_rotation")

func configure_for_team(new_team: TeamData, new_career: SavedCareer = null) -> void:
	team = new_team
	career = new_career
	selected_system = team.active_system if team != null else null
	if selected_system != null and not library.systems.has(selected_system):
		library.systems.append(selected_system)
	_refresh_system_lists()
	_set_editing(false)
	if selected_system != null:
		_refresh_controls_from_system(selected_system)

func open_for_team(new_team: TeamData, new_career: SavedCareer = null) -> void:
	configure_for_team(new_team, new_career)
	show()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not editor_tabs or editor_tabs.current_tab != 2:
		return
	if event.is_pressed() and event.keycode in [KEY_LEFT, KEY_A]:
		_set_rotation(selected_rotation - 1 if selected_rotation > 1 else 6)
		get_viewport().set_input_as_handled()
	elif event.is_pressed() and event.keycode in [KEY_RIGHT, KEY_D]:
		_set_rotation(selected_rotation + 1 if selected_rotation < 6 else 1)
		get_viewport().set_input_as_handled()

func _new_system() -> void:
	draft = SystemDefinition.new()
	draft.display_name = "New system"
	draft.ensure_id()
	draft.initialize_default_roles()
	selected_system = null
	editing_original = null
	_set_editing(true)
	_refresh_draft_controls()
	status.text = "New System draft"

func _edit_selected() -> void:
	if selected_system == null:
		return
	editing_original = selected_system
	draft = selected_system.duplicate_system() if default_systems.has(selected_system) else selected_system.duplicate(true)
	draft.initialize_default_roles()
	_set_editing(true)
	_refresh_draft_controls()
	status.text = "Editing a copy; the saved System is unchanged."

func _use_selected() -> void:
	if team == null or selected_system == null:
		return
	team.active_system = selected_system.duplicate_system()
	team.teamStrategy.active_system = team.active_system
	if career != null:
		career.SaveGame()
	status.text = "System selected for this team."

func _save_system() -> void:
	if draft == null:
		return
	_write_controls_to_draft()
	library.add_or_replace(draft)
	selected_system = draft
	if team != null and team.active_system != null and editing_original != null and team.active_system.id == editing_original.id:
		team.active_system = draft
		team.teamStrategy.active_system = team.active_system
		if career != null:
			career.SaveGame()
	_save_library()
	_set_editing(false)
	editing_original = null
	_refresh_system_lists()
	status.text = "System saved."

func _save_system_copy() -> void:
	if draft == null:
		return
	_write_controls_to_draft()
	draft = draft.duplicate_system()
	editing_original = null
	_save_system()
	status.text = "System saved as a copy."

func _load_library() -> void:
	if ResourceLoader.exists(SYSTEM_LIBRARY_PATH):
		var loaded = ResourceLoader.load(SYSTEM_LIBRARY_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
		if loaded is SystemCatalog:
			library = loaded
	if library == null:
		library = SystemCatalog.new()
	_refresh_system_lists()

func _save_library() -> void:
	if library == null:
		library = SystemCatalog.new()
	ResourceSaver.save(library, SYSTEM_LIBRARY_PATH)

func _load_default_systems() -> void:
	default_systems.clear()
	var blank := SystemDefinition.new()
	blank.id = "default-blank-system"
	blank.display_name = "Blank System"
	blank.guide_text = "A neutral starting point with no player responsibilities selected."
	blank.initialize_default_roles()
	default_systems.append(blank)
	default_system_list.clear()
	for system in default_systems:
		default_system_list.add_item(system.display_name)

func _refresh_system_lists() -> void:
	if saved_system_list == null or default_system_list == null or library == null:
		return
	saved_system_list.clear()
	for system in library.systems:
		if system != null:
			saved_system_list.add_item(system.display_name)
			if system == selected_system:
				saved_system_list.select(saved_system_list.item_count - 1)
	if selected_system != null and saved_system_list.get_selected_items().is_empty() and not default_system_list.get_selected_items().is_empty():
		_status_for_selected()

func _on_saved_system_selected(index: int) -> void:
	if library == null or index < 0 or index >= library.systems.size():
		return
	selected_system = library.systems[index]
	default_system_list.deselect_all()
	draft = null
	editing_original = null
	_set_editing(false)
	_refresh_controls_from_system(selected_system)
	_status_for_selected()

func _on_default_system_selected(index: int) -> void:
	if index < 0 or index >= default_systems.size():
		return
	selected_system = default_systems[index]
	saved_system_list.deselect_all()
	draft = null
	editing_original = null
	_set_editing(false)
	_refresh_controls_from_system(selected_system)
	_status_for_selected()

func _status_for_selected() -> void:
	status.text = "Selected System. Choose Edit to make a draft."

func _set_editing(enabled: bool) -> void:
	editing = enabled
	system_name.editable = enabled
	guide_text.editable = enabled
	for option in touch_options:
		option.disabled = not enabled
	for controls in role_controls:
		for key in ROLE_KEYS + ["backup_setter", "preparation"]:
			controls[key].disabled = not enabled
	edit_button.disabled = selected_system == null or enabled
	save_button.disabled = not enabled
	save_copy_button.disabled = not enabled
	check_button.disabled = not enabled
	$Margin/Root/Content/Editor/Tabs/PlayerRoles/RotationBar.mouse_filter = Control.MOUSE_FILTER_IGNORE if not enabled else Control.MOUSE_FILTER_STOP
	_refresh_constraints()
	_refresh_phase_constraints()
	if not enabled:
		validation_results.clear()

func _refresh_draft_controls() -> void:
	if draft == null:
		return
	_refresh_controls_from_system(draft)
	_refresh_constraints()
	_refresh_phase_constraints()

func _refresh_controls_from_system(system: TeamSystem) -> void:
	if system == null:
		return
	var controls: Array[Control] = [system_name, guide_text, first_touch, second_touch, third_touch]
	for role_control_set in role_controls:
		for key in ROLE_KEYS + ["backup_setter", "preparation"]:
			controls.append(role_control_set[key])
	for control in controls:
		control.set_block_signals(true)
	system_name.text = system.display_name
	guide_text.text = system.guide_text
	first_touch.select(system.first_touch)
	second_touch.select(system.second_touch)
	third_touch.select(system.third_touch)
	for index in range(6):
		var role: PlayerRoleDefinition = system.role_for(selected_rotation, index)
		for key in ROLE_KEYS + ["backup_setter"]:
			role_controls[index][key].button_pressed = _get_role_value(role, key)
		role_controls[index]["preparation"].select(role.non_receive_preparation if role != null else 0)
	for control in controls:
		control.set_block_signals(false)
	_refresh_constraints()
	_refresh_phase_constraints()

func _write_controls_to_draft() -> void:
	if draft == null:
		return
	draft.display_name = system_name.text
	draft.guide_text = guide_text.text
	draft.first_touch = first_touch.selected
	draft.second_touch = second_touch.selected
	draft.third_touch = third_touch.selected
	for index in range(6):
		var role: PlayerRoleDefinition = draft.role_for(selected_rotation, index)
		for key in ROLE_KEYS + ["backup_setter"]:
			_set_role_value(role, key, role_controls[index][key].button_pressed)
		role.non_receive_preparation = role_controls[index]["preparation"].selected

func _on_touch_goal_changed(_index: int) -> void:
	if draft == null:
		return
	var first := first_touch.selected
	if first == SystemDefinition.TouchGoal.PASS:
		second_touch.select(SystemDefinition.TouchGoal.SET)
		third_touch.select(SystemDefinition.TouchGoal.ATTACK)
	elif first == SystemDefinition.TouchGoal.SET:
		second_touch.select(SystemDefinition.TouchGoal.ATTACK)
		third_touch.select(SystemDefinition.TouchGoal.ATTACK)
	elif first == SystemDefinition.TouchGoal.ATTACK:
		second_touch.select(SystemDefinition.TouchGoal.ATTACK)
		third_touch.select(SystemDefinition.TouchGoal.ATTACK)
	_refresh_phase_constraints()
	_write_controls_to_draft()

func _refresh_phase_constraints() -> void:
	if draft == null:
		first_touch.disabled = not editing
		second_touch.disabled = true
		third_touch.disabled = true
		return
	first_touch.disabled = not editing
	second_touch.disabled = true
	third_touch.disabled = true
	match first_touch.selected:
		SystemDefinition.TouchGoal.PASS:
			second_touch.select(SystemDefinition.TouchGoal.SET)
			third_touch.select(SystemDefinition.TouchGoal.ATTACK)
		SystemDefinition.TouchGoal.SET:
			second_touch.select(SystemDefinition.TouchGoal.ATTACK)
			third_touch.select(SystemDefinition.TouchGoal.ATTACK)
		SystemDefinition.TouchGoal.ATTACK:
			second_touch.select(SystemDefinition.TouchGoal.ATTACK)
			third_touch.select(SystemDefinition.TouchGoal.ATTACK)

func _on_role_toggle(pressed: bool, index: int, key: String) -> void:
	if draft == null or not pressed:
		_refresh_constraints()
		return
	if _is_locked(index, key):
		role_controls[index][key].button_pressed = false
		_reject(role_controls[index][key], _lock_message(index, key))
		return
	var role: PlayerRoleDefinition = draft.player_roles[index]
	if key == "set" and _has_other_role_value(index, "set"):
		role_controls[index][key].button_pressed = false
		_reject(role_controls[index][key], "Only one setter may be selected in a System.")
		return
	if key == "backup_setter" and _has_other_role_value(index, "backup_setter"):
		role_controls[index][key].button_pressed = false
		_reject(role_controls[index][key], "Only one Backup Setter may be selected.")
		return
	if key in ["receive", "attack"]:
		role_controls[index]["set"].button_pressed = false
	if key == "set":
		role_controls[index]["receive"].button_pressed = false
		role_controls[index]["attack"].button_pressed = false
	_write_controls_to_draft()
	_refresh_constraints()

func _on_preparation_selected(_index: int, _player_index: int) -> void:
	_write_controls_to_draft()

func _has_other_role_value(index: int, key: String) -> bool:
	for other in range(6):
		if other != index and role_controls[other][key].button_pressed:
			return true
	return false

func _set_role_value(role: PlayerRoleDefinition, key: String, value: bool) -> void:
	match key:
		"receive": role.receive = value
		"set": role.set_role = value
		"attack": role.attack = value
		"block": role.block = value
		"defend": role.defend = value
		"backup_setter": role.backup_setter = value

func _get_role_value(role: PlayerRoleDefinition, key: String) -> bool:
	if role == null:
		return false
	match key:
		"receive": return role.receive
		"set": return role.set_role
		"attack": return role.attack
		"block": return role.block
		"defend": return role.defend
		"backup_setter": return role.backup_setter
	return false

func _is_locked(index: int, key: String) -> bool:
	var controls: Dictionary = role_controls[index]
	var physical_position := ((index + selected_rotation - 1) % 6) + 1
	if key == "block" and not _is_front_court(physical_position):
		return true
	if key == "defend" and controls["block"].button_pressed:
		return true
	if key == "set":
		return controls["receive"].button_pressed or controls["attack"].button_pressed
	if key in ["receive", "attack"]:
		return controls["set"].button_pressed
	if key == "backup_setter":
		for other in role_controls:
			if other["backup_setter"].button_pressed:
				return not controls["backup_setter"].button_pressed
	return false

func _lock_message(_index: int, key: String) -> String:
	if key == "block":
		return "Block is only available to front-court players in this rotation."
	if key == "defend":
		return "Untick Block before selecting Defend."
	if key == "set":
		return "Untick Receive or Attack before selecting Set."
	if key in ["receive", "attack"]:
		return "Untick Set before selecting %s." % key.capitalize()
	if key == "backup_setter":
		return "Only one Backup Setter may be selected."
	return "This responsibility is locked."

func _refresh_constraints() -> void:
	var has_setter := false
	var has_backup := false
	for controls in role_controls:
		has_setter = has_setter or controls["set"].button_pressed
		has_backup = has_backup or controls["backup_setter"].button_pressed
	for controls in role_controls:
		var player_index := role_controls.find(controls)
		var physical_position := ((player_index + selected_rotation - 1) % 6) + 1
		var receive_or_attack: bool = controls["receive"].button_pressed or controls["attack"].button_pressed
		var is_setter: bool = controls["set"].button_pressed
		var set_locked := receive_or_attack
		var receive_locked := is_setter
		var attack_locked := is_setter
		controls["backup_setter"].visible = has_setter and not is_setter
		var backup_locked: bool = has_backup and not controls["backup_setter"].button_pressed
		controls["set"].disabled = not editing
		controls["receive"].disabled = not editing
		controls["attack"].disabled = not editing
		controls["backup_setter"].disabled = not editing
		var block_locked := not _is_front_court(physical_position)
		var defend_locked: bool = controls["block"].button_pressed
		controls["block"].disabled = not editing
		controls["defend"].disabled = not editing
		controls["preparation"].disabled = not editing
		controls["preparation"].visible = not controls["receive"].button_pressed
		controls["set"].modulate = Color(0.55, 0.55, 0.55, 1.0) if set_locked else Color.WHITE
		controls["receive"].modulate = Color(0.55, 0.55, 0.55, 1.0) if receive_locked else Color.WHITE
		controls["attack"].modulate = Color(0.55, 0.55, 0.55, 1.0) if attack_locked else Color.WHITE
		controls["backup_setter"].modulate = Color(0.55, 0.55, 0.55, 1.0) if backup_locked else Color.WHITE
		controls["block"].modulate = Color(0.55, 0.55, 0.55, 1.0) if block_locked else Color.WHITE
		controls["defend"].modulate = Color(0.55, 0.55, 0.55, 1.0) if defend_locked else Color.WHITE
		controls["set"].tooltip_text = _lock_message(0, "set") if set_locked else ""
		controls["receive"].tooltip_text = _lock_message(0, "receive") if receive_locked else ""
		controls["attack"].tooltip_text = _lock_message(0, "attack") if attack_locked else ""
		controls["backup_setter"].tooltip_text = _lock_message(0, "backup_setter") if backup_locked else ""
		controls["block"].tooltip_text = _lock_message(0, "block") if block_locked else ""
		controls["defend"].tooltip_text = _lock_message(0, "defend") if defend_locked else ""

func _is_front_court(physical_position: int) -> bool:
	return physical_position >= 2 and physical_position <= 4

func _reject(control: Control, message: String) -> void:
	control.tooltip_text = message
	control.grab_focus()
	status.text = message

func _check_system() -> void:
	if draft == null:
		return
	_write_controls_to_draft()
	var findings := Validator.validate(draft)
	validation_results.clear()
	if findings.is_empty():
		validation_results.append_text("[color=#a6e3a1]No advice for this System. Unusual systems are allowed.[/color]")
		return
	for finding in findings:
		validation_results.append_text("[color=#ffd36c][b]Rotation %d - %s[/b][/color] %s\n" % [finding.rotation, finding.area, finding.message])

func _on_rotation_pressed(button: Button) -> void:
	_set_rotation(rotation_buttons.find(button) + 1)

func _set_rotation(new_rotation: int) -> void:
	selected_rotation = wrapi(new_rotation - 1, 0, 6) + 1
	if draft != null:
		_refresh_controls_from_system(draft)
	elif selected_system != null:
		_refresh_controls_from_system(selected_system)
	_refresh_rotation()

func _refresh_rotation() -> void:
	for index in range(rotation_buttons.size()):
		rotation_buttons[index].button_pressed = index + 1 == selected_rotation
	for index in range(role_cards.size()):
		var physical := ((index + selected_rotation - 1) % 6)
		var normalized: Vector2 = ROTATION_POSITIONS[physical]
		var court := role_cards[index].get_parent()
		role_cards[index].position = Vector2(normalized.x * court.size.x - role_cards[index].size.x * 0.5, normalized.y * court.size.y - role_cards[index].size.y * 0.5)
