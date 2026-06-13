extends GutTest

# Placeholder UI test skeleton for radial menu scene existence & basic API.

var RadialScenePath := "res://scenes/ui/radial_menu.tscn"

func test_radial_scene_exists():
	var exists = ResourceLoader.exists(RadialScenePath)
	assert_true(exists, "Radial menu scene should exist at %s" % RadialScenePath)

func test_radial_menu_exposes_open_method():
	if not ResourceLoader.exists(RadialScenePath):
		fail_test("Scene missing; implement radial_menu.tscn")
		return
	var scene = load(RadialScenePath)
	var inst = scene.instantiate()
	add_child_autofree(inst)
	assert_true(inst.has_method("open"), "Radial menu should implement open() method")
