extends Node

func _ready():
	var tile_map := $TileMapLayer
	$ResourceManager.essence_changed.connect(_on_essence_changed)
	_on_essence_changed(0, $ResourceManager.get_essence(0), 0, "initial")
	# Clicking a placed unit (or the Inspect action) shows its info.
	tile_map.unit_selected.connect($UnitInfoPanel.show_unit)
	# Deploy radial: preview the hovered unit in the same panel, and clear it
	# when the deploy radial closes (so it shows only while choosing).
	tile_map.deploy_unit_hovered.connect(_on_deploy_unit_hovered)
	tile_map.deploy_preview_ended.connect($UnitInfoPanel.hide_panel)

func _on_deploy_unit_hovered(unit_id: String) -> void:
	var data = $TileMapLayer.get_unit_type(unit_id)
	if data:
		$UnitInfoPanel.show_unit_type(data, $TileMapLayer.get_unit_artwork(unit_id))


func _on_essence_changed(player_id: int, total: int, _delta: int, _reason: String) -> void:
	if player_id == 0:
		$EssenceLabel.text = "Player 1 Essence: %d" % total
