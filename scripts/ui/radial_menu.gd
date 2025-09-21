extends Control

# Re-emit signals from the tile_map or deployment_controller
signal deploy_unit_hovered(unit_id)
signal deploy_unit_selected(unit_id, origin)
signal deploy_radial_closed(reason)

func open(origin_tile: Vector2i, units: Array):
    pass

func close(reason: String):
    pass
