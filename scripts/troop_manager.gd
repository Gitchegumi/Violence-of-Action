extends Node

# TroopManager is responsible for handling the placement of units on the map.
# Keep mechanics out of main.gd; this node is created/owned by the TileMap scene.

@export var tile_map: TileMapLayer
@export var shardwalker_scene: PackedScene = preload("res://scenes/armies/coreborn/ShardWalker.tscn")

# Where your .tres live (adjust to your layout)
@export var units_dirs: Array[String] = [
	"res://assets/data/armies/TheCoreborn/tier-1",
	"res://assets/data/armies/TheCoreborn/tier-2",
	"res://assets/data/armies/TheCoreborn/tier-3",
]

# id -> UnitData
var catalog: Dictionary = {}
var current_unit_id: String = ""

# map_pos (Vector2i) -> Unit
var units_on_map: Dictionary = {}

func _ready():
	_load_unit_catalog()

func _load_unit_catalog():
	catalog.clear()
	for dir_path in units_dirs:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			push_warning("TroopManager: could not open " + dir_path)
			continue
		dir.list_dir_begin()
		while true:
			var f = dir.get_next()
			if f == "": break
			if dir.current_is_dir(): continue
			if f.ends_with(".tres"):
				var res: Resource = ResourceLoader.load(dir_path + "/" + f)
				if res and res is UnitType:
					catalog[f.get_basename()] = res
		dir.list_dir_end()

	# Pick a default unit if none selected
	if current_unit_id == "" and catalog.size() > 0:
		current_unit_id = catalog.keys()[0]

func set_current_unit(id: String) -> void:
	if catalog.has(id):
		current_unit_id = id
	else:
		push_warning("Unknown unit id: " + id)

func place_unit(map_pos: Vector2i, player_id: int = 0) -> bool:
	if tile_map == null: return false
	if units_on_map.has(map_pos): return false
	if current_unit_id == "" or not catalog.has(current_unit_id):
		push_warning("No unit selected for placement.")
		return false

	# Example passability gate: only land for now
	var terrain: TerrainType = tile_map.terrain_data_map.get(map_pos)
	if terrain == null or terrain.passable_by != "land":
		return false

	var u: ShardWalker = shardwalker_scene.instantiate()
	u.data = catalog[current_unit_id]
	u.map_pos = map_pos
	u.controller_player_id = player_id
	u.position = _center_of_tile(map_pos)
	# Scale the unit down for tile map placement
	u.scale = Vector2(0.15, 0.15)
	tile_map.add_child(u)
	units_on_map[map_pos] = u
	u.selected.connect(_on_unit_selected)
	return true

func count_units(unit_id: String, player_id: int) -> int:
	var expected: UnitType = catalog.get(unit_id)
	if expected == null:
		return 0
	var count := 0
	for unit in units_on_map.values():
		if unit == null or not unit.has_method("get_unit_data"):
			continue
		if int(unit.get("controller_player_id")) != player_id:
			continue
		var actual: UnitType = unit.get_unit_data()
		if actual == expected or (
			actual != null
			and not actual.resource_path.is_empty()
			and actual.resource_path == expected.resource_path
		):
			count += 1
	return count

func get_unit_at_map_coord(map_pos: Vector2i) -> Node:
	if units_on_map.has(map_pos):
		return units_on_map[map_pos]
	return null

# Returns a standalone artwork node for a unit type (for info-panel previews of
# not-yet-placed units). get_artwork_node() returns a duplicate, so freeing the
# temporary scene instance is safe.
func get_unit_artwork(unit_id: String) -> Node:
	var scene := _scene_for_unit_id(unit_id)
	if scene == null:
		return null
	var inst := scene.instantiate()
	var artwork: Node = null
	if inst.has_method("get_artwork_node"):
		artwork = inst.get_artwork_node()
	inst.free()
	return artwork

func _scene_for_unit_id(unit_id: String) -> PackedScene:
	# Only the Shard Walker has a scene wired up so far.
	if unit_id == "shard_walker":
		return shardwalker_scene
	return null

func _center_of_tile(map_pos: Vector2i) -> Vector2:
	# For hex stairs right layout, Godot's map_to_local returns the center
	return tile_map.map_to_local(map_pos)

func _on_unit_selected(unit: ShardWalker):
	print("Selected: ", unit.data.unit_name, " @ ", unit.map_pos)
