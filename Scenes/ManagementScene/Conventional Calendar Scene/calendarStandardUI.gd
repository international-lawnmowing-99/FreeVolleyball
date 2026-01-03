extends Control

@onready var month_label = $VBoxContainer/Header/Label
@onready var grid = $VBoxContainer/GridContainer

var selected_year : int
var selected_month : int

# Example dummy events
var events := {
	"2025-11-03": ["Game vs Thunder", "Team Dinner"],
	"2025-11-08": ["Training 7PM"],
	"2025-11-15": ["Game vs Sharks"],
	"2025-11-22": ["Rest Day"],
	"2025-12-02": ["Preseason Meeting"]
}

# Month name lookup table (since get_month_name() was removed)
const MONTH_NAMES := [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]


func _ready() -> void:
	var now := Time.get_datetime_dict_from_system()
	selected_year = now.year
	selected_month = now.month
	_draw_calendar()


func _draw_calendar() -> void:
	# Clear old day buttons
	for child in grid.get_children():
		child.queue_free()

	# Update header label
	month_label.text = "%s %d" % [MONTH_NAMES[selected_month - 1], selected_year]

	var days_in_month := _get_days_in_month(selected_month, selected_year)

	# Determine weekday of first day (Mon=1 … Sun=7)
	var first_day_unix := Time.get_unix_time_from_datetime_dict({
		"year": selected_year, "month": selected_month, "day": 1,
		"hour": 0, "minute": 0, "second": 0
	})
	var first_day := Time.get_datetime_dict_from_unix_time(first_day_unix)
	var first_weekday : int = first_day.weekday

	# Fill blank cells before first day
	for i in range(first_weekday - 1):
		grid.add_child(Control.new())

	# Add one button per day
	for day in range(1, days_in_month + 1):
		var btn := Button.new()
		btn.text = str(day)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.connect("pressed", Callable(self, "_on_day_pressed").bind(day))

		var date_key := "%04d-%02d-%02d" % [selected_year, selected_month, day]
		if events.has(date_key):
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.tooltip_text = "\n".join(events[date_key])
		grid.add_child(btn)


func _get_days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if _is_leap_year(year) else 28
		_:
			return 30


func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)


func _on_day_pressed(day: int) -> void:
	var date_key := "%04d-%02d-%02d" % [selected_year, selected_month, day]
	if events.has(date_key):
		print("Events for %s:" % date_key)
		for e in events[date_key]:
			print("  - " + e)
	else:
		print("No events for %s" % date_key)


func _on_prev_month_pressed() -> void:
	selected_month -= 1
	if selected_month < 1:
		selected_month = 12
		selected_year -= 1
	_draw_calendar()


func _on_next_month_pressed() -> void:
	selected_month += 1
	if selected_month > 12:
		selected_month = 1
		selected_year += 1
	_draw_calendar()
