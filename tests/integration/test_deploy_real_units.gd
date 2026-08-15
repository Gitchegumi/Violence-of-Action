extends GutTest

# Verifies the real data and shared sprite-sheet pipeline used by the Coreborn
# MVP deployment radial.

var TroopManagerScript = preload("res://scripts/troop_manager.gd")
var TileMapScript = preload("res://scripts/tile_map.gd")
var MockUnit = preload("res://tests/unit/mock_unit.gd")
var MainScene = preload("res://scenes/main.tscn")

const EXPECTED_ARTWORK_REGIONS := {
	"battlefield_scavenger": Rect2(35, 545, 210, 285),
	"fluxsmith": Rect2(20, 80, 300, 320),
	"ghostthorn": Rect2(360, 80, 300, 320),
	"golemancer_hull": Rect2(690, 80, 300, 320),
	"shard_walker": Rect2(258, 548, 236, 301),
	"sky_render": Rect2(500, 520, 300, 320),
	"tide_born": Rect2(790, 570, 205, 260),
}


func before_each():
	get_tree().paused = false
	GameState.begin_match({"player_count": 2, "seed": 982451653})


func after_each():
	get_tree().paused = false
	GameSession.clear_match_config()
	GameState.return_to_menu()
	GameState.active_player_id = 0


func _gameplay_tile_map():
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main.get_node("TileMapLayer")


func _place_passive_opposing_unit(tile_map) -> void:
	assert_true(tile_map.troop_manager.place_unit(tile_map.deployment_zones_data[1][0], 1))


func _place_adjacent_opponents(tile_map) -> Array:
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	var target := Vector2i(-999, -999)
	for neighbor in tile_map._get_neighbors(origin):
		var terrain: TerrainType = tile_map.terrain_data_map.get(neighbor)
		if terrain != null and terrain.passable_by == "land":
			target = neighbor
			break
	assert_ne(target, Vector2i(-999, -999), "generated map offers an adjacent combat target")
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	assert_true(tile_map.troop_manager.place_unit(target, 1))
	return [
		tile_map.troop_manager.get_unit_at_map_coord(origin),
		tile_map.troop_manager.get_unit_at_map_coord(target),
	]

func test_shard_walker_loads_from_catalog():
	var tm = TroopManagerScript.new()
	add_child_autofree(tm)
	await get_tree().process_frame  # let _ready populate the catalog
	assert_eq(tm.unit_scene.resource_path, "res://scenes/units/unit.tscn")
	assert_true(tm.catalog.has("shard_walker"), "catalog loads the shard_walker UnitType")
	var data = tm.catalog.get("shard_walker")
	assert_eq(data.unit_name, "Shardwalker")
	assert_eq(data.get_cost(0), 2, "Shard Walker cost matches GAME_RULES.md")

func test_shard_walker_resource_fields():
	var data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	assert_not_null(data, "shard_walker.tres loads")
	assert_eq(data.unit_role, "Core Infantry")
	assert_true(data.stats_block.has("health"), "stats_block has health")
	assert_false(data.can_upgrade, "upgrade mechanics remain disabled while GAME_RULES.md marks them TBD")
	# No upgrade target wired yet -> the Upgrade action should render disabled.
	assert_null(data.upgrades_to, "no upgrade target set yet")


func test_live_deployment_roster_exposes_all_seven_coreborn_profiles_in_order():
	var tile_map = await _gameplay_tile_map()
	var roster: Array = tile_map._get_deployable_units()
	var ids: Array = roster.map(func(unit): return unit.unit_id)
	assert_eq(ids, [
		"battlefield_scavenger",
		"fluxsmith",
		"ghostthorn",
		"golemancer_hull",
		"shard_walker",
		"sky_render",
		"tide_born",
	])
	assert_eq(roster.size(), 7)
	for quote in roster:
		assert_same(tile_map.get_unit_type(quote.unit_id), tile_map.troop_manager.catalog[quote.unit_id])
		assert_true(quote.affordable, "%s is affordable from the initial 12 essence" % quote.unit_name)


func test_every_coreborn_profile_places_with_its_own_stats_and_artwork_region():
	var tile_map = await _gameplay_tile_map()
	var roster: Array = tile_map._get_deployable_units()
	var land_tiles: Array = tile_map.deployment_zones_data[0].slice(0, roster.size())
	assert_eq(land_tiles.size(), 7)
	var unique_regions: Dictionary = {}
	for region in EXPECTED_ARTWORK_REGIONS.values():
		unique_regions[region] = true
	assert_eq(unique_regions.size(), roster.size(), "every Coreborn profile uses a distinct crop")
	for index in range(roster.size()):
		var quote: Dictionary = roster[index]
		var expected_region: Rect2 = EXPECTED_ARTWORK_REGIONS[quote.unit_id]
		tile_map.troop_manager.set_current_unit(quote.unit_id)
		assert_true(tile_map.troop_manager.place_unit(land_tiles[index], 0), "%s places" % quote.unit_name)
		var placed: Node = tile_map.troop_manager.get_unit_at_map_coord(land_tiles[index])
		assert_not_null(placed)
		assert_true(placed is Unit, "%s uses the profile-neutral Unit runtime" % quote.unit_name)
		assert_same(placed.get_unit_data(), tile_map.troop_manager.catalog[quote.unit_id])
		assert_eq(placed.current_hp, int(quote.stats_block.health), "%s HP comes from its profile" % quote.unit_name)
		assert_eq(placed.movement_remaining, int(quote.stats_block.speed), "%s Speed comes from its profile" % quote.unit_name)
		assert_eq(placed.get_unit_data().artwork_region, expected_region, "%s stores its crop" % quote.unit_name)
		assert_eq(placed.get_node("UnitArtwork").region_rect, expected_region, "%s board art" % quote.unit_name)
		var artwork: Node = tile_map.get_unit_artwork(quote.unit_id)
		assert_not_null(artwork, "%s has preview artwork" % quote.unit_name)
		assert_eq(artwork.region_rect, expected_region, "%s preview art" % quote.unit_name)
		artwork.free()


func test_placed_units_use_their_players_configured_colors():
	GameSession.set_match_config({
		"player_count": 2,
		"seed": 982451653,
		"players": [
			{"name": "Alpha", "color": Color(0.3, 0.7, 1.0)},
			{"name": "Bravo", "color": Color(1.0, 0.3, 0.3)},
		],
	})
	var tile_map = await _gameplay_tile_map()
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(tile_map.deployment_zones_data[0][0], 0))
	assert_true(tile_map.troop_manager.place_unit(tile_map.deployment_zones_data[1][0], 1))
	var player_one = tile_map.troop_manager.get_units_for_player(0)[0]
	var player_two = tile_map.troop_manager.get_units_for_player(1)[0]
	assert_eq(player_one.get_node("UnitArtwork").modulate, Color(0.3, 0.7, 1.0))
	assert_eq(player_two.get_node("UnitArtwork").modulate, Color(1.0, 0.3, 0.3))
	assert_true(tile_map.get_parent().get_node("TurnLabel").text.contains("Alpha"))


func test_scavenger_roster_quote_tracks_live_on_field_count():
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("battlefield_scavenger")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	var roster: Array = tile_map._get_deployable_units()
	var scavenger: Dictionary = roster.filter(func(unit): return unit.unit_id == "battlefield_scavenger")[0]
	assert_eq(scavenger.unit_cost, 2, "second Scavenger preview uses the live Fibonacci cost")
	assert_true(tile_map.troop_manager.destroy_unit(
		tile_map.troop_manager.get_unit_at_map_coord(origin),
		"destroyed_scavenger",
	))
	roster = tile_map._get_deployable_units()
	scavenger = roster.filter(func(unit): return unit.unit_id == "battlefield_scavenger")[0]
	assert_eq(scavenger.unit_cost, 1, "price drops when an on-field Scavenger is destroyed")


func test_hover_panel_uses_the_live_roster_quote():
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("battlefield_scavenger")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	tile_map.current_radial_units = tile_map._get_deployable_units()
	var main: Node = tile_map.get_parent()
	main._on_deploy_unit_hovered("battlefield_scavenger")
	var panel: Control = main.get_node("UnitInfoPanel")
	assert_true(panel.visible)
	assert_eq(panel.get_node("Panel/UnitCostLabel").text, "Cost: 2")

func test_occupied_tile_actions_are_attack_move_upgrade_inspect():
	var tm = TileMapScript.new()  # not added to tree: avoids scene-only @onready
	tm.troop_manager = TroopManagerScript.new()
	tm.troop_manager.tile_map = tm
	var mock = MockUnit.new()
	mock.unit_data = load("res://assets/data/armies/TheCoreborn/tier-1/shard_walker.tres")
	var actions = tm._build_unit_actions(mock)
	var ids := []
	for a in actions:
		ids.append(a.action_id)
	assert_eq(actions.size(), 4, "four action options")
	assert_true(ids.has("attack") and ids.has("move") and ids.has("upgrade") and ids.has("inspect"),
		"actions are Attack/Move/Upgrade/Inspect")
	for a in actions:
		if a.action_id == "upgrade":
			assert_false(a.enabled, "Upgrade disabled (Shard Walker has no upgrade target)")
		elif a.action_id in ["move", "attack"]:
			assert_false(a.enabled, "%s disabled outside its active phase" % a.action_id.capitalize())
		else:
			assert_true(a.enabled, "%s enabled" % a.action_id)
	mock.free()
	tm.troop_manager.free()
	tm.free()

func test_unsafe_upgrade_path_stays_disabled_without_spending():
	var tile_map = await _gameplay_tile_map()
	var upgraded := UnitType.new()
	upgraded.unit_name = "Upgrade Target"
	var source := UnitType.new()
	source.unit_name = "Upgradeable Unit"
	source.can_upgrade = true
	source.upgrade_cost = 3
	source.upgrades_to = upgraded
	var mock = MockUnit.new()
	mock.unit_data = source
	var actions: Array = tile_map._build_unit_actions(mock)
	var upgrade_action: Dictionary = actions.filter(func(action): return action.action_id == "upgrade")[0]
	assert_false(upgrade_action.enabled, "upgrade fails closed without authoritative combat safety state")
	var starting_essence: int = tile_map.get_player_essence()
	tile_map._upgrade_unit(mock, Vector2i.ZERO)
	assert_eq(tile_map.get_player_essence(), starting_essence, "rejected upgrade spends no essence")
	assert_same(mock.get_unit_data(), source, "rejected upgrade does not change unit data")
	mock.free()

func test_successive_dynamic_cost_deployments_revalidate_live_unit_count():
	var tile_map = await _gameplay_tile_map()
	var scavenger: UnitType = tile_map.troop_manager.catalog.get("battlefield_scavenger")
	assert_not_null(scavenger, "production catalog exposes Battlefield Scavenger data")
	var land_tiles: Array = tile_map.deployment_zones_data[GameState.active_player_id].slice(0, 2)
	assert_eq(land_tiles.size(), 2, "active player has two deployable land tiles")
	var stale_quote: Dictionary = tile_map._unit_type_to_dict("battlefield_scavenger", scavenger)
	assert_eq(stale_quote.unit_cost, 1, "first Scavenger quote uses first Fibonacci price")
	tile_map.current_radial_units = [stale_quote]
	tile_map._on_radial_unit_selected("battlefield_scavenger", land_tiles[0])
	assert_eq(tile_map.get_player_essence(), 11)
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 1)
	# Reuse the stale 1-Essence quote: confirmation must resolve the live cost as 2.
	tile_map.current_radial_units = [stale_quote]
	tile_map._on_radial_unit_selected("battlefield_scavenger", land_tiles[1])
	assert_eq(tile_map.get_player_essence(), 9, "second Scavenger charges the live Fibonacci price")
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 2)


func test_deployment_rejects_every_non_marshal_playing_phase_without_spending():
	var tile_map = await _gameplay_tile_map()
	GameState.start_playing_for_test(2)
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	var scavenger: UnitType = tile_map.troop_manager.catalog.get("battlefield_scavenger")
	var quote: Dictionary = tile_map._unit_type_to_dict("battlefield_scavenger", scavenger)
	var starting_essence: int = tile_map.get_player_essence()
	var blocked_phases := [
		GameState.TurnPhase.START_TURN,
		GameState.TurnPhase.MOVEMENT,
		GameState.TurnPhase.COMBAT,
		GameState.TurnPhase.RESOLVE,
		GameState.TurnPhase.CLEAN_UP,
	]
	for blocked_phase in blocked_phases:
		GameState.current_phase = blocked_phase
		tile_map.current_radial_units = [quote]
		tile_map._on_radial_unit_selected("battlefield_scavenger", origin)
		assert_eq(tile_map.get_player_essence(), starting_essence, "phase rejection spends no essence")
		assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 0)


func test_marshal_deployment_charges_and_assigns_the_active_player():
	var tile_map = await _gameplay_tile_map()
	GameState.start_playing_for_test(2)
	GameState.active_player_id = 1
	GameState.current_phase = GameState.TurnPhase.MARSHAL_TROOPS
	var origin: Vector2i = tile_map.deployment_zones_data[1][0]
	var scavenger: UnitType = tile_map.troop_manager.catalog.get("battlefield_scavenger")
	tile_map.current_radial_units = [tile_map._unit_type_to_dict("battlefield_scavenger", scavenger)]
	var starting_essence: int = tile_map.get_player_essence()
	tile_map._on_radial_unit_selected("battlefield_scavenger", origin)
	assert_eq(tile_map.get_player_essence(), starting_essence - 1)
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 0), 0)
	assert_eq(tile_map.troop_manager.count_units("battlefield_scavenger", 1), 1)


func test_p_shortcut_opens_purchase_flow_without_free_placement():
	var tile_map = await _gameplay_tile_map()
	tile_map.selected_tile = tile_map.deployment_zones_data[0][0]
	var starting_essence: int = tile_map.get_player_essence()
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_P
	shortcut.pressed = true
	tile_map._unhandled_input(shortcut)
	assert_not_null(tile_map.radial_menu_instance, "shortcut opens the purchase radial")
	assert_eq(tile_map.get_player_essence(), starting_essence, "opening purchase flow spends nothing")
	assert_eq(tile_map.troop_manager.get_units_for_player(0).size(), 0, "shortcut cannot place a free unit")


func test_live_move_target_flow_relocates_unit_and_spends_speed():
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	_place_passive_opposing_unit(tile_map)
	var destination := Vector2i(-999, -999)
	for neighbor in tile_map._get_neighbors(origin):
		var terrain: TerrainType = tile_map.terrain_data_map.get(neighbor)
		if terrain != null and terrain.terrain_name.to_lower() in ["field", "forest", "objective"]:
			destination = neighbor
			break
	assert_ne(destination, Vector2i(-999, -999), "generated map offers an adjacent legal destination")
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	var unit = tile_map.troop_manager.get_unit_at_map_coord(origin)
	var starting_movement: int = unit.movement_remaining
	tile_map._begin_pending_action("move", unit, origin)
	assert_true(tile_map.get_action_highlighted_cells().has(destination))
	assert_eq(tile_map.action_highlight_layer.modulate, tile_map.MOVE_HIGHLIGHT_COLOR)
	tile_map._resolve_pending_action(destination)
	assert_same(tile_map.troop_manager.get_unit_at_map_coord(destination), unit)
	assert_null(tile_map.troop_manager.get_unit_at_map_coord(origin))
	assert_lt(unit.movement_remaining, starting_movement)
	var movement_label: Label = tile_map.get_parent().get_node("UnitInfoPanel/Panel/MovementLabel")
	assert_true(movement_label.visible)
	assert_eq(movement_label.text, "Movement: %d/%d" % [unit.movement_remaining, starting_movement])
	assert_true(tile_map.pending_action.is_empty())
	assert_true(tile_map.get_action_highlighted_cells().is_empty())


func test_right_click_cancels_live_move_targeting():
	var tile_map = await _gameplay_tile_map()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	_place_passive_opposing_unit(tile_map)
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	tile_map._begin_pending_action("move", tile_map.troop_manager.get_unit_at_map_coord(origin), origin)
	assert_false(tile_map.pending_action.is_empty())
	assert_false(tile_map.get_action_highlighted_cells().is_empty())
	var cancel := InputEventMouseButton.new()
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	tile_map._unhandled_input(cancel)
	assert_true(tile_map.pending_action.is_empty())
	assert_true(tile_map.get_action_highlighted_cells().is_empty())


func test_visible_cancel_button_clears_move_targeting():
	var tile_map = await _gameplay_tile_map()
	var main = tile_map.get_parent()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	_place_passive_opposing_unit(tile_map)
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	tile_map._begin_pending_action("move", tile_map.troop_manager.get_unit_at_map_coord(origin), origin)
	assert_true(main.get_node("CancelActionButton").visible)
	assert_eq(main.get_node("CancelActionButton").text, "Cancel Move")
	main.get_node("CancelActionButton").pressed.emit()
	assert_true(tile_map.pending_action.is_empty())
	assert_false(main.get_node("CancelActionButton").visible)


func test_phase_advance_automatically_clears_pending_action_for_next_player():
	var tile_map = await _gameplay_tile_map()
	var main = tile_map.get_parent()
	var origin: Vector2i = tile_map.deployment_zones_data[0][0]
	tile_map.troop_manager.set_current_unit("shard_walker")
	assert_true(tile_map.troop_manager.place_unit(origin, 0))
	_place_passive_opposing_unit(tile_map)
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.MOVEMENT
	tile_map.troop_manager.start_turn(0)
	tile_map._begin_pending_action("move", tile_map.troop_manager.get_unit_at_map_coord(origin), origin)
	assert_false(tile_map.pending_action.is_empty())
	assert_true(GameState.advance_phase())
	assert_true(tile_map.pending_action.is_empty(), "phase boundary cannot leak targeting state")
	assert_false(main.get_node("CancelActionButton").visible)


func test_live_attack_target_flow_uses_seeded_combat_resolution():
	var tile_map = await _gameplay_tile_map()
	var units := _place_adjacent_opponents(tile_map)
	var attacker: Node = units[0]
	var defender: Node = units[1]
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.COMBAT
	tile_map.troop_manager.start_turn(0)
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 424242
	var expected_dice := [expected_rng.randi_range(1, 6), expected_rng.randi_range(1, 6)]
	tile_map.map_rng.seed = 424242
	var observed_results := []
	tile_map.unit_attack_resolved.connect(func(_attacker, _defender, result): observed_results.append(result))
	tile_map._begin_pending_action("attack", attacker, attacker.map_pos)
	assert_eq(tile_map.pending_action.type, "attack")
	assert_eq(tile_map.get_action_highlighted_cells(), [defender.map_pos])
	assert_eq(tile_map.action_highlight_layer.modulate, tile_map.ATTACK_HIGHLIGHT_COLOR)
	tile_map._resolve_pending_action(defender.map_pos)
	assert_true(tile_map.pending_action.is_empty())
	assert_true(tile_map.get_action_highlighted_cells().is_empty())
	assert_eq(observed_results.size(), 1)
	assert_eq([observed_results[0].die_one, observed_results[0].die_two], expected_dice)
	assert_eq(observed_results[0].attack_total, observed_results[0].natural_roll + 1)
	var defender_terrain: TerrainType = tile_map.terrain_data_map.get(defender.map_pos)
	var expected_defense := 9 if defender_terrain.terrain_name.to_lower() == "forest" else 8
	assert_eq(observed_results[0].defense_target, expected_defense)
	assert_true(attacker.attacked_this_turn)
	assert_true(tile_map.get_parent().get_node("CombatResultLabel").visible)
	assert_true(tile_map.get_parent().get_node("CombatResultLabel").text.contains("Attack:"))


func test_destroyed_unit_reaches_scavenger_reporting_exactly_once():
	var tile_map = await _gameplay_tile_map()
	var main = tile_map.get_parent()
	var units := _place_adjacent_opponents(tile_map)
	var attacker: Node = units[0]
	var defender: Node = units[1]
	defender.current_hp = 1
	GameState.start_playing_for_test(2)
	GameState.current_phase = GameState.TurnPhase.COMBAT
	var result: Dictionary = tile_map.troop_manager.resolve_attack(attacker, defender, 6, 6)
	assert_true(result.destroyed)
	assert_eq(main.get_node("ResourceManager").pending_destructions[0].size(), 1)
	assert_eq(main.get_node("ResourceManager").pending_destructions[1].size(), 1)
	var repeated: Dictionary = tile_map.troop_manager.resolve_attack(attacker, defender, 6, 6)
	assert_false(repeated.success)
	assert_eq(main.get_node("ResourceManager").pending_destructions[0].size(), 1)
	assert_eq(main.get_node("ResourceManager").pending_destructions[1].size(), 1)
