extends GutTest

# Repeated open/close cycles must not leak orphan nodes (T030, T011).
# Uses GUT's built-in per-test orphan counter via assert_no_new_orphans().

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")

func _units_count(n: int) -> Array:
	var arr := []
	for i in range(n):
		arr.append({
			"unit_id": "u%d" % i, "unit_name": "Unit %d" % i, "unit_cost": 1,
			"affordable": true, "stats_block": {}, "abilities": "",
		})
	return arr

func test_no_leaks_after_many_cycles():
	for i in range(20):
		var m = RadialScene.instantiate()
		m.size = Vector2(400, 400)
		add_child(m)
		m.open(Vector2i(0, 0), _units_count(6))
		m.close("cancel")
		m.queue_free()
		await get_tree().process_frame
	# Let the final deferred frees settle before counting orphans.
	await get_tree().process_frame
	await get_tree().process_frame
	assert_no_new_orphans("radial open/close cycles should not leak nodes")
