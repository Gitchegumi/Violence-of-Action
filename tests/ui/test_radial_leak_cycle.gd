extends GutTest

# Repeated open/close cycles must not leak orphan nodes (T030, T011).

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")
var _orphan_counter = preload('res://addons/gut/orphan_counter.gd').new()

func _units_count(n: int) -> Array:
	var arr := []
	for i in range(n):
		arr.append({
			"unit_id": "u%d" % i, "unit_name": "Unit %d" % i, "unit_cost": 1,
			"affordable": true, "stats_block": {}, "abilities": "",
		})
	return arr

func before_all():
	_orphan_counter.start()

func after_all():
	var orphans = _orphan_counter.stop()
	assert_eq(orphans, 0, 'Should not have any orphan nodes after test.')

func test_no_leaks_after_many_cycles():
	for i in range(20):
		var m = RadialScene.instantiate()
		m.size = Vector2(400, 400)
		add_child(m)
		m.open(Vector2i(0, 0), _units_count(6))
		m.close("cancel")
		m.queue_free()
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(true, "completed open/close cycles without errors")
