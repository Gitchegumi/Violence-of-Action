extends GutTest

var _orphan_counter = preload('res://addons/gut/orphan_counter.gd').new()

func before_all():
    _orphan_counter.start()

func after_all():
    var orphans = _orphan_counter.stop()
    assert_eq(orphans, 0, 'Should not have any orphan nodes after test.')

func test_no_leaks_after_many_cycles():
    assert_true(false, 'Not implemented')
