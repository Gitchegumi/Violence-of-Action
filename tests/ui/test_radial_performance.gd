extends GutTest

# Performance micro-check (T037): open/close the radial many times and report
# average per-cycle time. This is a smoke-level guard, not a strict benchmark;
# it asserts the cycle stays comfortably fast and logs anomalies.

var RadialScene = preload("res://scenes/ui/radial_menu.tscn")

const CYCLES := 50
const MAX_AVG_MS := 5.0  # generous headroom; flags gross regressions only

func _units_count(n: int) -> Array:
	var arr := []
	for i in range(n):
		arr.append({
			"unit_id": "u%d" % i, "unit_name": "Unit %d" % i, "unit_cost": 1,
			"affordable": true, "stats_block": {}, "abilities": "",
		})
	return arr

func test_open_close_cycle_is_fast():
	var units := _units_count(12)
	var start_us := Time.get_ticks_usec()
	for i in range(CYCLES):
		var m = RadialScene.instantiate()
		m.size = Vector2(400, 400)
		add_child(m)
		m.open(Vector2i(0, 0), units)
		m.close("cancel")
		m.free()
	var total_ms := float(Time.get_ticks_usec() - start_us) / 1000.0
	var avg_ms := total_ms / float(CYCLES)
	gut.p("Radial open/close avg: %.3f ms over %d cycles" % [avg_ms, CYCLES])
	assert_lt(avg_ms, MAX_AVG_MS, "open/close cycle should stay well under one frame")
