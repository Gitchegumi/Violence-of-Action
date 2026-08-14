extends Control

# Radial deployment menu. Owns an ephemeral RadialMenuSession while open:
# the ordered/paginated unit list, the focus index, and placement debounce
# state. Re-emits the deployment signals so a controller (tile_map.gd or a
# future deployment_controller.gd) can react without depending on internals.

signal deploy_unit_hovered(unit_id)
signal deploy_unit_unhovered
signal deploy_unit_selected(unit_id, origin)
signal deploy_radial_closed(reason)
signal deploy_placement_failed(reason, origin, unit_id)
signal deploy_action_selected(action_id, origin)

# DEPLOY: items are deployable units (place on confirm).
# ACTION: items are unit actions for an occupied tile (emit action on confirm).
enum Mode { DEPLOY, ACTION }

const PAGE_SIZE := 12
const RADIUS := 80.0
const ICON_SIZE := Vector2(60, 60)
const DEBOUNCE_MS := 250
const LOG_CHANNEL := "deployment.radial"

# Tests and profiling may disable console I/O so timing reflects radial UI work
# instead of the debug logger. Normal gameplay keeps diagnostics enabled.
@export var debug_logging_enabled := true

# --- Session state (see data-model.md: RadialMenuSession) ---
# Note: all_units/visible_units/unit_icons hold whatever the current mode
# presents — deployable unit dicts in DEPLOY mode, action dicts in ACTION mode.
var mode: int = Mode.DEPLOY
var all_units: Array = []        # Full ordered list across all pages
var visible_units: Array = []    # Current page slice
var unit_icons: Array = []       # Button refs for current page
var origin_position: Vector2i
var focus_index: int = 0
var page_index: int = 0
var active: bool = false
var last_selection_time_ms: int = 0

var _prev_button: Button = null
var _next_button: Button = null

# Optional hook: a controller sets this Callable to supply the placement
# context dict ({resources, tile_valid, tile_occupied, now_ms}) when a unit is
# confirmed. When unset (e.g. in unit tests) confirmation just emits
# deploy_unit_selected so the controller can validate downstream.
var placement_context_provider: Callable = Callable()
# Set false when the origin tile is invalidated mid-session (T032): blocks
# placement but still allows cancel.
var origin_valid: bool = true


func _ready() -> void:
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_right"):
		focus_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		focus_previous()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_confirm_item(get_focused_unit())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close("cancel")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right-click cancels (T031).
		close("cancel")
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# A left-click that reaches here landed outside any icon -> cancel (T031).
		# (Icon Buttons consume their own clicks before _unhandled_input.)
		close("cancel")
		get_viewport().set_input_as_handled()


# --- Lifecycle ---

func open(origin_tile: Vector2i, units: Array) -> void:
	"""Open the radial menu around origin_tile with deployable units."""
	mode = Mode.DEPLOY
	_open_common(origin_tile, units)
	_log("Opened deploy radial at %s with %d units" % [str(origin_tile), units.size()])


func open_actions(origin_tile: Vector2i, actions: Array) -> void:
	"""Open the radial menu around an occupied tile with unit actions."""
	mode = Mode.ACTION
	_open_common(origin_tile, actions)
	_log("Opened action radial at %s with %d actions" % [str(origin_tile), actions.size()])


func is_action_mode() -> bool:
	return mode == Mode.ACTION


func _open_common(origin_tile: Vector2i, items: Array) -> void:
	origin_position = origin_tile
	all_units = items
	page_index = 0
	focus_index = 0
	active = true
	origin_valid = true
	last_selection_time_ms = 0
	_rebuild()
	_select_initial_focus()
	show()
	set_process_unhandled_input(true)


func close(reason: String) -> void:
	"""Close the radial menu, free icons, hide the info panel, emit closed."""
	active = false
	set_process_unhandled_input(false)
	_clear_ui()
	hide()
	emit_signal("deploy_radial_closed", reason)
	_log("Closed radial (%s)" % reason)


# --- Page building ---

func _rebuild() -> void:
	_clear_ui()
	var total_pages := _page_count()
	page_index = clampi(page_index, 0, maxi(0, total_pages - 1))
	var start := page_index * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, all_units.size())
	visible_units = all_units.slice(start, end)
	_create_unit_icons()
	_create_pagination_controls()
	focus_index = clampi(focus_index, 0, maxi(0, visible_units.size() - 1))
	_update_focus_visual()


func _create_unit_icons() -> void:
	var angle_step := TAU / maxf(1.0, float(visible_units.size()))
	for i in range(visible_units.size()):
		var item: Dictionary = visible_units[i]
		var icon := Button.new()
		icon.name = "UnitIcon%d" % i
		icon.text = _item_text(item)
		icon.custom_minimum_size = ICON_SIZE
		var icon_angle := i * angle_step
		var offset := Vector2(RADIUS * cos(icon_angle), RADIUS * sin(icon_angle))
		icon.position = offset + size / 2.0 - ICON_SIZE / 2.0
		_apply_affordability_visual(icon, item)
		if not icon.disabled:
			icon.pressed.connect(_on_icon_pressed.bind(i))
		icon.mouse_entered.connect(_on_icon_hovered.bind(i))
		icon.mouse_exited.connect(_on_icon_unhovered)
		add_child(icon)
		unit_icons.append(icon)


func _item_text(item: Dictionary) -> String:
	if mode == Mode.ACTION:
		return item.get("label", "Action")
	return "%s\n(%d)" % [item.get("unit_name", "Unit"), int(item.get("unit_cost", 0))]


func _item_enabled(item: Dictionary) -> bool:
	if mode == Mode.ACTION:
		return item.get("enabled", true)
	return item.get("affordable", true)


func _create_pagination_controls() -> void:
	if not has_pagination():
		return
	_prev_button = Button.new()
	_prev_button.name = "PrevPageButton"
	_prev_button.text = "<"
	_prev_button.custom_minimum_size = Vector2(40, 40)
	_prev_button.position = size / 2.0 + Vector2(-RADIUS - 20.0, -RADIUS - 20.0)
	_prev_button.pressed.connect(prev_page)
	add_child(_prev_button)

	_next_button = Button.new()
	_next_button.name = "NextPageButton"
	_next_button.text = ">"
	_next_button.custom_minimum_size = Vector2(40, 40)
	_next_button.position = size / 2.0 + Vector2(RADIUS - 20.0, -RADIUS - 20.0)
	_next_button.pressed.connect(next_page)
	add_child(_next_button)


func _clear_ui() -> void:
	for icon in unit_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	unit_icons.clear()
	if is_instance_valid(_prev_button):
		_prev_button.queue_free()
	_prev_button = null
	if is_instance_valid(_next_button):
		_next_button.queue_free()
	_next_button = null


# --- Pagination (T028) ---

func _page_count() -> int:
	if all_units.is_empty():
		return 1
	return int(ceil(float(all_units.size()) / float(PAGE_SIZE)))


func has_pagination() -> bool:
	return all_units.size() > PAGE_SIZE


func next_page() -> void:
	if not has_pagination():
		return
	page_index = (page_index + 1) % _page_count()
	focus_index = 0
	_rebuild()
	_emit_focus_hover()


func prev_page() -> void:
	if not has_pagination():
		return
	page_index = (page_index - 1 + _page_count()) % _page_count()
	focus_index = 0
	_rebuild()
	_emit_focus_hover()


# --- Focus navigation (T019-T022) ---

func focus_next() -> void:
	if visible_units.is_empty():
		return
	focus_index = (focus_index + 1) % visible_units.size()
	_update_focus_visual()
	_emit_focus_hover()


func focus_previous() -> void:
	if visible_units.is_empty():
		return
	focus_index = (focus_index - 1 + visible_units.size()) % visible_units.size()
	_update_focus_visual()
	_emit_focus_hover()


func set_focus_from_vector(direction: Vector2) -> void:
	"""Map a directional input vector (center -> icon) to the nearest icon."""
	if direction.length() == 0.0:
		return
	set_focus_from_angle(direction.angle())


func set_focus_from_angle(angle_rad: float) -> void:
	if visible_units.is_empty():
		return
	var angle_step := TAU / float(visible_units.size())
	var best_i := 0
	var best_diff := TAU
	for i in range(visible_units.size()):
		var icon_angle := i * angle_step
		var diff: float = absf(wrapf(angle_rad - icon_angle, -PI, PI))
		if diff < best_diff:
			best_diff = diff
			best_i = i
	focus_index = best_i
	_update_focus_visual()
	_emit_focus_hover()


func _select_initial_focus() -> void:
	"""DEPLOY: focus the lowest-cost unit (T022). ACTION: first enabled action."""
	if visible_units.is_empty():
		return
	var best_i := 0
	if mode == Mode.ACTION:
		for i in range(visible_units.size()):
			if _item_enabled(visible_units[i]):
				best_i = i
				break
	else:
		var best_cost := INF
		for i in range(visible_units.size()):
			var cost: float = float(visible_units[i].get("unit_cost", 0))
			if cost < best_cost:
				best_cost = cost
				best_i = i
	focus_index = best_i
	_update_focus_visual()
	_emit_focus_hover()


func get_focused_unit() -> Dictionary:
	if focus_index >= 0 and focus_index < visible_units.size():
		return visible_units[focus_index]
	return {}


func _emit_focus_hover() -> void:
	var item := get_focused_unit()
	if item.is_empty():
		return
	# Unit info on hover only applies to deployable units (DEPLOY mode). The
	# controller listens to deploy_unit_hovered and drives the shared info panel.
	if mode == Mode.ACTION:
		return
	emit_signal("deploy_unit_hovered", item.get("unit_id", ""))


func _update_focus_visual() -> void:
	for i in range(unit_icons.size()):
		var icon: Button = unit_icons[i]
		if not is_instance_valid(icon):
			continue
		# Focus ring: brighten focused icon, keep enabled/disabled tint otherwise.
		var item: Dictionary = visible_units[i] if i < visible_units.size() else {}
		var enabled: bool = _item_enabled(item)
		if i == focus_index:
			icon.modulate = Color(1.2, 1.2, 0.7) if enabled else Color(0.8, 0.6, 0.6)
		else:
			icon.modulate = Color.WHITE if enabled else Color(0.5, 0.5, 0.5, 0.6)
			icon.scale = Vector2.ONE
	_animate_focus_ring()


func _animate_focus_ring() -> void:
	"""Subtle scale pop on the focused icon when focus changes (T035)."""
	if focus_index < 0 or focus_index >= unit_icons.size():
		return
	var icon: Button = unit_icons[focus_index]
	if not is_instance_valid(icon) or not is_inside_tree():
		return
	icon.pivot_offset = icon.size / 2.0
	var tween := create_tween()
	tween.tween_property(icon, "scale", Vector2(1.15, 1.15), 0.08)


# --- Hover (T019) ---

func _on_icon_hovered(index: int) -> void:
	if index < 0 or index >= visible_units.size():
		return
	focus_index = index
	_update_focus_visual()
	_emit_focus_hover()


func _on_icon_unhovered() -> void:
	# Mouse left a unit icon -> clear the deploy hover preview (DEPLOY only).
	if mode == Mode.ACTION:
		return
	emit_signal("deploy_unit_unhovered")


func _on_icon_pressed(index: int) -> void:
	if index < 0 or index >= visible_units.size():
		return
	focus_index = index
	_confirm_item(visible_units[index])


func _confirm_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	if mode == Mode.ACTION:
		if not _item_enabled(item):
			return
		emit_signal("deploy_action_selected", item.get("action_id", ""), origin_position)
		_log("Action selected: %s at %s" % [item.get("action_id", ""), str(origin_position)])
		return
	# DEPLOY mode: confirm a unit placement.
	if placement_context_provider.is_valid():
		attempt_placement(item, placement_context_provider.call())
	else:
		emit_signal("deploy_unit_selected", item.get("unit_id", ""), origin_position)


# --- Placement & validation (T024-T027) ---

func attempt_placement(unit: Dictionary, context: Dictionary) -> Dictionary:
	"""Validate a placement attempt in deterministic precedence order:
	debounce -> resources -> invalid tile -> occupied. On success emit
	deploy_unit_selected; on any failure emit deploy_placement_failed."""
	var now_ms: int = context.get("now_ms", Time.get_ticks_msec())
	var unit_id: String = unit.get("unit_id", "")

	# Origin invalidated mid-session (T032): block placement, allow cancel.
	if not origin_valid:
		return _fail_placement("invalid_tile", unit_id)

	# Debounce guard (T026)
	if last_selection_time_ms != 0 and now_ms - last_selection_time_ms < DEBOUNCE_MS:
		return _fail_placement("debounced", unit_id)

	# Affordability first (T024 precedence: resources > tile)
	if int(context.get("resources", 0)) < int(unit.get("unit_cost", 0)):
		return _fail_placement("insufficient_resources", unit_id)

	# Tile validity / zone ownership
	if not bool(context.get("tile_valid", true)):
		return _fail_placement("invalid_tile", unit_id)

	# Tile occupancy
	if bool(context.get("tile_occupied", false)):
		return _fail_placement("tile_occupied", unit_id)

	# Success
	last_selection_time_ms = now_ms
	emit_signal("deploy_unit_selected", unit_id, origin_position)
	_log("Placed %s at %s" % [unit_id, str(origin_position)])
	return {"success": true, "reason": "placed"}


func _fail_placement(reason: String, unit_id: String) -> Dictionary:
	emit_signal("deploy_placement_failed", reason, origin_position, unit_id)
	_flash_failure()
	_log("Placement failed (%s) for %s" % [reason, unit_id])
	return {"success": false, "reason": reason}


func _flash_failure() -> void:
	"""Visual feedback for a failed placement (T025): brief outline flash."""
	if focus_index < 0 or focus_index >= unit_icons.size():
		return
	var icon: Button = unit_icons[focus_index]
	if not is_instance_valid(icon):
		return
	var tween := create_tween()
	tween.tween_property(icon, "modulate", Color(1.0, 0.2, 0.2), 0.08)
	tween.tween_property(icon, "modulate", Color.WHITE, 0.12)


func revalidate_affordability(resources: int) -> void:
	"""Re-evaluate affordability of all units after a resource change (T027)."""
	for unit in all_units:
		unit["affordable"] = resources >= int(unit.get("unit_cost", 0))
	_refresh_icon_states()


func _refresh_icon_states() -> void:
	for i in range(mini(unit_icons.size(), visible_units.size())):
		var icon: Button = unit_icons[i]
		if is_instance_valid(icon):
			_apply_affordability_visual(icon, visible_units[i])
	_update_focus_visual()


func _apply_affordability_visual(icon: Button, item: Dictionary) -> void:
	if not _item_enabled(item):
		# Disabled visual: grayed-out, dimmed, with red cost styling (T034).
		icon.modulate = Color(0.5, 0.5, 0.5, 0.6)
		icon.disabled = true
		icon.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		icon.add_theme_color_override("font_disabled_color", Color(0.9, 0.3, 0.3))
	else:
		icon.modulate = Color.WHITE
		icon.disabled = false
		icon.add_theme_color_override("font_color", Color.WHITE)


# --- Origin invalidation (T032) ---

func invalidate_origin() -> void:
	"""Mark the radial's origin tile as no longer valid; placement is blocked
	but the player may still cancel."""
	origin_valid = false
	_log("Origin tile invalidated for radial at %s" % str(origin_position))


# --- Edge repositioning (T029) ---

func reposition_within_viewport(viewport_size: Vector2) -> void:
	"""Clamp the menu inward so the full icon ring stays visible near edges."""
	var margin := RADIUS + ICON_SIZE.x
	var pos := position
	pos.x = clampf(pos.x, margin, maxf(margin, viewport_size.x - margin))
	pos.y = clampf(pos.y, margin, maxf(margin, viewport_size.y - margin))
	position = pos


# --- Logging (T033) ---

func _log(message: String) -> void:
	if debug_logging_enabled:
		GameLog.debug(LOG_CHANNEL, message)
