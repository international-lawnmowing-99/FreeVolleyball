extends Control
class_name PlayerRoleEditor

const RoleDefinition = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleDefinition.gd")
const RoleLibrary = preload("res://_newhierarchy/simulation/team/roles/PlayerRoleLibrary.gd")
const Override = preload("res://_newhierarchy/simulation/team/roles/PlayerRolePositionOverride.gd")
const Validator = preload("res://_newhierarchy/simulation/team/roles/RoleLineupValidator.gd")
const CourtPreview = preload("res://Scenes/ManagementScene/Roles/RoleCourtPreview.gd")

const ROLE_LIBRARY_PATH := "user://player_roles.tres"
const PHASES := ["receive", "set", "attack", "block", "defence"]

var team: TeamData
var career: SavedCareer
var library: PlayerRoleLibrary
var selected_role: PlayerRoleDefinition
var role_list: ItemList
var name_edit: LineEdit
var instruction_controls := {}
var rotation_option: OptionButton
var phase_option: OptionButton
var preview: RoleCourtPreview
var override_position: SpinBox
var override_rotations := []
var lineup_options := []
var results: RichTextLabel
var status: Label

func _ready() -> void:
	_build_ui()
	if team == null:
		_load_standalone_library()
	_refresh()

func configure_for_team(new_team: TeamData, new_career: SavedCareer = null) -> void:
	team = new_team
	career = new_career
	if team != null:
		if team.roleLibrary == null:
			team.roleLibrary = RoleLibrary.new()
		library = team.roleLibrary
	_refresh()

func open_for_team(new_team: TeamData, new_career: SavedCareer = null) -> void:
	configure_for_team(new_team, new_career)
	show()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.04, 0.06, 0.98)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new(); title.text = "Player Roles"; title.add_theme_font_size_override("font_size", 28); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	status = Label.new(); status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; header.add_child(status)
	var close := Button.new(); close.text = "Close"; close.pressed.connect(hide); header.add_child(close)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(body)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 220; body.add_child(left)
	role_list = ItemList.new(); role_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; role_list.item_selected.connect(_on_role_selected); left.add_child(role_list)
	var library_buttons := HBoxContainer.new(); left.add_child(library_buttons)
	_add_button(library_buttons, "New", _new_role)
	_add_button(library_buttons, "Copy", _copy_role)
	_add_button(library_buttons, "Delete", _delete_role)
	_add_button(left, "Load library", _load_standalone_library)
	_add_button(left, "Save library", _save_standalone_library)
	var editor_scroll := ScrollContainer.new(); editor_scroll.custom_minimum_size.x = 330; editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(editor_scroll)
	var editor := VBoxContainer.new(); editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; editor_scroll.add_child(editor)
	name_edit = LineEdit.new(); name_edit.placeholder_text = "Role name"; name_edit.text_changed.connect(_on_name_changed); editor.add_child(name_edit)
	_add_section(editor, "Receive")
	_add_check(editor, "Designated receiver", "designated_receiver")
	_add_option(editor, "If not receiving", "non_receiver_preparation", ["None", "Prepare to set second ball", "Prepare attack"])
	_add_section(editor, "Set")
	_add_check(editor, "Setter for good pass", "designated_setter_good_pass")
	_add_check(editor, "Backup if setter receives", "backup_setter_if_primary_receives")
	_add_check(editor, "Emergency setter if designated options cannot reach", "emergency_setter")
	_add_section(editor, "Attack")
	_add_option(editor, "Front-court attack", "front_attack_lane", ["None", "Left", "Middle", "Right"])
	_add_option(editor, "Back-court attack", "back_attack_lane", ["None", "Left", "Middle", "Right"])
	_add_section(editor, "Block")
	_add_check(editor, "Designated blocker when front court", "designated_front_blocker")
	_add_option(editor, "Block lane", "block_lane", ["None", "Left", "Middle", "Right"])
	_add_section(editor, "Defence")
	_add_check(editor, "Defensive position when back court", "defend_in_back_court")
	_add_option(editor, "Defensive position", "defensive_slot", ["None", "Left", "Middle", "Right"])
	_add_section(editor, "Physical-position instruction")
	var position_row := HBoxContainer.new(); editor.add_child(position_row)
	position_row.add_child(_label("Court position")); override_position = SpinBox.new(); override_position.min_value = 1; override_position.max_value = 6; override_position.value = 1; position_row.add_child(override_position)
	var rotations_row := HBoxContainer.new(); editor.add_child(rotations_row); rotations_row.add_child(_label("Rotations"))
	for rotation in range(1, 7):
		var toggle := CheckButton.new(); toggle.text = str(rotation); toggle.button_pressed = true; rotations_row.add_child(toggle); override_rotations.append(toggle)
	_add_button(editor, "Apply current instructions to selected rotations", _apply_position_override)
	_add_button(editor, "Remove matching physical-position instruction", _remove_position_override)
	var right := VBoxContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(right)
	var controls := HBoxContainer.new(); right.add_child(controls)
	controls.add_child(_label("Rotation"))
	rotation_option = OptionButton.new()
	for number in range(1, 7):
		rotation_option.add_item(str(number))
	rotation_option.item_selected.connect(_preview_changed)
	controls.add_child(rotation_option)
	controls.add_child(_label("Phase"))
	phase_option = OptionButton.new()
	for item in PHASES:
		phase_option.add_item(item.capitalize())
	phase_option.item_selected.connect(_preview_changed)
	controls.add_child(phase_option)
	preview = CourtPreview.new(); preview.custom_minimum_size = Vector2(520, 430); preview.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(preview)
	_add_section(right, "Proposed six-role lineup")
	var lineup_grid := GridContainer.new(); lineup_grid.columns = 2; right.add_child(lineup_grid)
	for slot in range(1, 7):
		lineup_grid.add_child(_label("Player slot %d" % slot)); var option := OptionButton.new(); option.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lineup_grid.add_child(option); lineup_options.append(option)
	_add_button(right, "Check all rotations", _check_lineup)
	results = RichTextLabel.new(); results.bbcode_enabled = true; results.fit_content = false; results.custom_minimum_size.y = 150; results.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(results)
	var save_row := HBoxContainer.new(); root.add_child(save_row)
	_add_button(save_row, "Save roles to team", _save_roles)
	_add_button(save_row, "Overwrite selected role", _overwrite_selected)

func _label(text: String) -> Label:
	var value := Label.new(); value.text = text; return value

func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text; button.pressed.connect(callback); parent.add_child(button); return button

func _add_section(parent: Node, text: String) -> void:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", 18); label.add_theme_color_override("font_color", Color("8ed6ff")); parent.add_child(label)

func _add_check(parent: Node, text: String, key: String) -> void:
	var control := CheckButton.new(); control.text = text; control.toggled.connect(func(_value): _write_form_to_role()); parent.add_child(control); instruction_controls[key] = control

func _add_option(parent: Node, text: String, key: String, items: Array) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(_label(text))
	var control := OptionButton.new()
	for item in items:
		control.add_item(item)
	control.item_selected.connect(func(_index): _write_form_to_role())
	row.add_child(control)
	instruction_controls[key] = control

func _new_role() -> void:
	if library == null: library = RoleLibrary.new()
	var role := RoleDefinition.new(); role.display_name = "New role"; role.ensure_id(); library.roles.append(role); selected_role = role; _refresh()

func _copy_role() -> void:
	if selected_role == null: return
	var copy := selected_role.duplicate_role(); library.roles.append(copy); selected_role = copy; _refresh()

func _delete_role() -> void:
	if selected_role == null or library == null: return
	library.remove_role(selected_role); selected_role = null; _refresh()

func _on_role_selected(index: int) -> void:
	if library != null and index >= 0 and index < library.roles.size(): selected_role = library.roles[index]; _refresh_form(); _refresh_preview()

func _on_name_changed(value: String) -> void:
	if selected_role != null: selected_role.display_name = value; _refresh_role_list(); _refresh_preview()

func _write_form_to_role() -> void:
	if selected_role == null: return
	for key in instruction_controls:
		var control = instruction_controls[key]
		selected_role.set(key, control.button_pressed if control is CheckButton else control.selected)
	_refresh_preview()

func _apply_position_override() -> void:
	if selected_role == null: return
	var rotations: Array[int] = []
	for index in override_rotations.size():
		if override_rotations[index].button_pressed: rotations.append(index + 1)
	if rotations.is_empty(): status.text = "Select at least one rotation."; return
	var physical := int(override_position.value)
	_remove_override(physical, rotations)
	var scoped := Override.new(); scoped.physical_position = physical; scoped.rotations = rotations; scoped.instructions = selected_role._base_instructions(); selected_role.position_overrides.append(scoped)
	status.text = "Physical-position instruction applied."; _refresh_preview()

func _remove_position_override() -> void:
	if selected_role == null: return
	var rotations: Array[int] = []
	for index in override_rotations.size():
		if override_rotations[index].button_pressed: rotations.append(index + 1)
	_remove_override(int(override_position.value), rotations); status.text = "Matching instruction removed."; _refresh_preview()

func _remove_override(physical: int, rotations: Array[int]) -> void:
	for index in range(selected_role.position_overrides.size() - 1, -1, -1):
		var item = selected_role.position_overrides[index]
		if item != null and item.physical_position == physical and item.rotations == rotations: selected_role.position_overrides.remove_at(index)

func _preview_changed(_ignored: int) -> void: _refresh_preview()

func _refresh_preview() -> void:
	if preview == null: return
	var display_roles: Array[PlayerRoleDefinition] = []
	for slot in range(6): display_roles.append(selected_role)
	if lineup_options.size() == 6:
		display_roles = _lineup_roles(false)
		if selected_role != null and display_roles.all(func(role): return role == null): display_roles[0] = selected_role
	preview.configure(rotation_option.selected + 1, PHASES[phase_option.selected], display_roles, team.roleTacticalSystem if team != null else null)

func _lineup_roles(require_all: bool) -> Array[PlayerRoleDefinition]:
	var selected: Array[PlayerRoleDefinition] = []
	for option in lineup_options:
		var id: Variant = option.get_item_metadata(option.selected)
		var role: PlayerRoleDefinition = library.find_role(id) if library != null and id != null else null
		selected.append(role)
	if require_all and selected.has(null): return []
	return selected

func _check_lineup() -> void:
	var findings := Validator.validate(_lineup_roles(false), team.roleTacticalSystem if team != null else null)
	results.clear()
	for finding in findings:
		var colour := "#ff7777" if finding.level == "Error" else "#ffd36c" if finding.level == "Warning" else "#a6e3a1"
		var where: String = "Rotation %d • %s" % [finding.rotation, finding.phase] if finding.rotation > 0 else str(finding.phase)
		results.append_text("[color=%s][b]%s[/b][/color] %s — %s\n" % [colour, finding.level, where, finding.message])

func _save_roles() -> void:
	if team != null:
		team.roleLibrary = library
		if career != null: career.SaveGame()
		status.text = "Roles saved with the team career."
	else:
		_save_standalone_library()

func _overwrite_selected() -> void:
	if selected_role == null: return
	library.add_or_replace(selected_role); _save_roles(); _refresh()

func _save_standalone_library() -> void:
	if library == null: library = RoleLibrary.new()
	var error := ResourceSaver.save(library, ROLE_LIBRARY_PATH)
	status.text = "Role library saved." if error == OK else "Could not save role library (%d)." % error

func _load_standalone_library() -> void:
	if ResourceLoader.exists(ROLE_LIBRARY_PATH):
		var loaded = ResourceLoader.load(ROLE_LIBRARY_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
		if loaded is PlayerRoleLibrary: library = loaded
	if library == null: library = RoleLibrary.new()
	if team != null: team.roleLibrary = library
	status.text = "Role library loaded."; _refresh()

func _refresh() -> void:
	if not is_node_ready(): return
	if library == null: library = team.roleLibrary if team != null and team.roleLibrary != null else RoleLibrary.new()
	if selected_role == null and not library.roles.is_empty(): selected_role = library.roles[0]
	_refresh_role_list(); _refresh_form(); _refresh_lineup_options(); _refresh_preview()

func _refresh_role_list() -> void:
	if role_list == null: return
	role_list.clear()
	for index in library.roles.size():
		var role = library.roles[index]; role_list.add_item(role.display_name if role != null else "Invalid role"); if role == selected_role: role_list.select(index)

func _refresh_form() -> void:
	if name_edit == null: return
	name_edit.text = selected_role.display_name if selected_role != null else ""
	for key in instruction_controls:
		var control = instruction_controls[key]
		if control is CheckButton: control.button_pressed = bool(selected_role.get(key)) if selected_role != null else false
		else: control.select(int(selected_role.get(key)) if selected_role != null else 0)

func _refresh_lineup_options() -> void:
	for option in lineup_options:
		var prior = option.get_selected_metadata(); option.clear(); option.add_item("Unassigned"); option.set_item_metadata(0, "")
		for role in library.roles:
			option.add_item(role.display_name)
			option.set_item_metadata(option.item_count - 1, role.id)
		for index in option.item_count:
			if option.get_item_metadata(index) == prior: option.select(index)
