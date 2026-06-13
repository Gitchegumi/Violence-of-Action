extends Control

# Radial Unit Info Panel
# Shows unit details when hovering over / focusing radial menu icons.

@onready var unit_icon: TextureRect = $UnitIcon
@onready var unit_name: Label = $UnitName
@onready var stats_container: VBoxContainer = $StatsContainer
@onready var abilities_text: RichTextLabel = $AbilitiesText

var current_unit_data: Dictionary = {}

func _ready():
	hide()  # Hidden by default

func show_unit(unit):
	"""Display unit information and make panel visible."""
	# Accept a plain Dictionary or a mock object exposing `unit_data`.
	var unit_data: Dictionary
	if unit is Dictionary:
		unit_data = unit
	elif unit and "unit_data" in unit and unit.unit_data:
		unit_data = unit.unit_data
	else:
		unit_data = {}

	current_unit_data = unit_data

	# Name
	unit_name.text = unit_data.get("unit_name", "Unknown Unit")

	# Stats (T023): rebuild the stat rows from the unit's stats_block.
	_bind_stats(unit_data.get("stats_block", {}))

	# Abilities (T023): accept either a String or an Array of ability names.
	_bind_abilities(unit_data.get("abilities", ""))

	show()

func _bind_stats(stats) -> void:
	for child in stats_container.get_children():
		child.queue_free()
	if stats is Dictionary:
		for stat_name in stats:
			var label := Label.new()
			label.text = "%s: %s" % [str(stat_name).capitalize(), str(stats[stat_name])]
			stats_container.add_child(label)

func _bind_abilities(abilities) -> void:
	if abilities is Array:
		if abilities.is_empty():
			abilities_text.text = "Abilities: (none)"
		else:
			abilities_text.text = "Abilities: " + ", ".join(abilities)
	else:
		var text := str(abilities)
		abilities_text.text = text if text != "" else "Abilities: (none)"

func hide_panel():
	"""Hide the panel."""
	hide()
	current_unit_data.clear()

func is_panel_visible() -> bool:
	"""Check if panel is currently visible."""
	return visible
