extends Control

# Radial Unit Info Panel
# Shows unit details when hovering over radial menu icons

@onready var unit_icon: TextureRect = $UnitIcon
@onready var unit_name: Label = $UnitName  
@onready var stats_container: VBoxContainer = $StatsContainer
@onready var abilities_text: RichTextLabel = $AbilitiesText

var current_unit_data: Dictionary = {}

func _ready():
	hide()  # Hidden by default

func show_unit(unit):
	"""Display unit information and make panel visible"""
	# Handle mock object with unit_data property (as per test)
	var unit_data: Dictionary
	if unit.has_method("get") and unit.get("unit_data"):
		unit_data = unit.unit_data
	elif "unit_data" in unit:
		unit_data = unit.unit_data
	else:
		unit_data = unit if unit is Dictionary else {}
	
	current_unit_data = unit_data
	
	# Bind data to UI elements (basic implementation)
	if unit_data.has("unit_name"):
		unit_name.text = unit_data.unit_name
	else:
		unit_name.text = "Unknown Unit"
		
	# For now, just make visible - detailed binding in T023
	show()
	
func hide_panel():
	"""Hide the panel"""
	hide()
	current_unit_data.clear()

func is_panel_visible() -> bool:
	"""Check if panel is currently visible"""
	return visible