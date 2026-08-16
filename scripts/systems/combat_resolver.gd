extends RefCounted
class_name CombatResolver

const BASE_DEFENSE_TARGET := 8


static func resolve_attack(
	attacker: Node,
	defender: Node,
	die_one: int,
	die_two: int,
	defense_modifier: int = 0
) -> Dictionary:
	assert(die_one in range(1, 7) and die_two in range(1, 7), "Combat dice must be d6 values")
	var natural_roll := die_one + die_two
	var attack_value := _stat(attacker, "attack")
	var armor_value := _stat(defender, "armor")
	var attack_total := natural_roll + attack_value
	var defense_target := BASE_DEFENSE_TARGET + armor_value + defense_modifier
	var hit := natural_roll == 12 or (natural_roll != 2 and attack_total >= defense_target)
	var damage := 1 if hit else 0
	if hit:
		defender.current_hp = maxi(0, int(defender.current_hp) - damage)
	return {
		"die_one": die_one,
		"die_two": die_two,
		"natural_roll": natural_roll,
		"attack_value": attack_value,
		"attack_total": attack_total,
		"base_defense_target": BASE_DEFENSE_TARGET,
		"armor_value": armor_value,
		"defense_modifier": defense_modifier,
		"defense_target": defense_target,
		"hit": hit,
		"damage": damage,
		"remaining_hp": int(defender.current_hp),
		"destroyed": int(defender.current_hp) == 0,
	}


static func _stat(unit: Node, stat_name: String) -> int:
	var data = unit.get_unit_data() if unit != null and unit.has_method("get_unit_data") else null
	if data == null:
		return 0
	if data is Dictionary:
		return int(data.get("stats_block", {}).get(stat_name, 0))
	return int(data.stats_block.get(stat_name, 0))
