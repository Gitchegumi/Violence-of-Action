extends Node

func _ready():
	# Connect unit selection signal to UI panel
	$TileMapLayer.unit_selected.connect($UnitInfoPanel.show_unit)
