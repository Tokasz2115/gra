extends Node2D
## Gracz. Porusza się WASD lub strzałkami i sam strzela w najbliższego wroga.
## Wszystkie statystyki są zwykłymi zmiennymi, więc ulepszenia z upgrades.gd
## po prostu je zmieniają.

signal leveled_up
signal died

const ProjectileScript := preload("res://scripts/projectile.gd")
const BLADE_RADIUS := 58.0
const BLADE_HIT_RADIUS := 9.0
const TARGET_RANGE := 480.0

var max_hp := 100.0
var hp := 100.0
var level := 1
var xp := 0
var need := 5
var pending_levels := 0

# Statystyki zmieniane przez ulepszenia
var damage := 10.0
var cooldown := 0.9
var proj_count := 1
var pierce := 0
var proj_speed := 420.0
var move_speed := 150.0
var magnet := 70.0
var regen := 0.0
var blades := 0

var upgrade_levels := {}

var _fire_timer := 0.3
var _inv := 0.0
var _face := Vector2.RIGHT
var _blade_angle := 0.0
var _dead := false


func _ready() -> void:
	add_to_group("player")
	var cam := Camera2D.new()
	add_child(cam)


func _process(delta: float) -> void:
	if _dead:
		return

	# Ruch
	var dir := Vector2(
		_axis(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT),
		_axis(KEY_W, KEY_UP, KEY_S, KEY_DOWN)
	)
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dir != Vector2.ZERO:
		_face = dir.normalized()
	position += dir * move_speed * delta

	# Regeneracja i nietykalność po trafieniu
	if regen > 0.0:
		hp = minf(max_hp, hp + regen * delta)
	_inv = maxf(0.0, _inv - delta)

	# Automatyczny atak
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		var target := _nearest_enemy(TARGET_RANGE)
		if target != null:
			_fire(target)
			_fire_timer = cooldown
		else:
			_fire_timer = 0.1

	# Ostrza orbitalne
	_blade_angle += 3.0 * delta
	for i in blades:
		var a := _blade_angle + i * TAU / blades
		var bpos := position + Vector2.from_angle(a) * BLADE_RADIUS
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or e.blade_cd > 0.0:
				continue
			var reach: float = e.radius + BLADE_HIT_RADIUS
			if bpos.distance_squared_to(e.position) < reach * reach:
				e.take_damage(damage * 0.6)
				e.blade_cd = 0.35

	queue_redraw()


func hurt(amount: float) -> void:
	if _dead or _inv > 0.0:
		return
	hp -= amount
	_inv = 0.5
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		died.emit()


func add_xp(value: int) -> void:
	xp += value
	var gained := false
	while xp >= need:
		xp -= need
		level += 1
		need = _need_for(level)
		pending_levels += 1
		gained = true
	if gained:
		leveled_up.emit()


func apply_upgrade(upgrade: Dictionary) -> void:
	upgrade["apply"].call(self)
	var id: String = upgrade["id"]
	upgrade_levels[id] = upgrade_levels.get(id, 0) + 1


func boost_hp(amount: float) -> void:
	max_hp += amount
	hp = minf(max_hp, hp + amount)


func _need_for(lvl: int) -> int:
	return roundi(5.0 + (lvl - 1) * 4.0 + pow(lvl - 1, 1.5))


func _axis(neg_a: Key, neg_b: Key, pos_a: Key, pos_b: Key) -> float:
	var neg := Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b)
	var pos := Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b)
	return float(pos) - float(neg)


func _nearest_enemy(max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist * max_dist
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e.is_queued_for_deletion():
			continue
		var d := position.distance_squared_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _fire(target: Node2D) -> void:
	var base := (target.position - position).angle()
	for i in proj_count:
		var a := base + (i - (proj_count - 1) / 2.0) * 0.18
		var p = ProjectileScript.new()
		p.position = position
		p.velocity = Vector2.from_angle(a) * proj_speed
		p.damage = damage
		p.pierce = pierce
		get_parent().add_child(p)


func _draw() -> void:
	# Ostrza
	for i in blades:
		var a := _blade_angle + i * TAU / blades
		var c := Vector2.from_angle(a) * BLADE_RADIUS
		var fwd := Vector2.from_angle(a + PI / 2.0)
		var out := Vector2.from_angle(a)
		draw_colored_polygon(PackedVector2Array([
			c + out * 11.0, c + fwd * 6.0 - out * 6.0, c - fwd * 6.0 - out * 6.0,
		]), Color(0.91, 0.93, 0.96))

	# Postać
	var blink := _inv > 0.0 and int(_inv * 20.0) % 2 == 0
	draw_circle(Vector2.ZERO, 11.0, Color(0.94, 0.28, 0.44) if blink else Color(1.0, 0.71, 0.33))
	draw_circle(_face * 5.0, 3.0, Color(0.05, 0.06, 0.09))
