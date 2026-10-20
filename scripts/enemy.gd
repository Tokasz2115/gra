extends Node2D
## Wróg. Idzie prosto na gracza i zadaje obrażenia przy dotyku.
## Po śmierci wysyła sygnał "died", a main.gd tworzy w tym miejscu gem.

signal died(pos: Vector2, gem_value: int)

## Typy wrogów. Aby dodać nowy, dopisz tu kolejny wpis
## i użyj go w funkcji _spawn_enemy w main.gd.
const TYPES := {
	"basic": {"radius": 10.0, "hp": 14.0, "speed": 55.0, "damage": 8.0, "color": Color(0.61, 0.36, 0.9), "gem": 1},
	"fast": {"radius": 8.0, "hp": 8.0, "speed": 105.0, "damage": 6.0, "color": Color(0.95, 0.36, 0.71), "gem": 1},
	"tank": {"radius": 16.0, "hp": 60.0, "speed": 38.0, "damage": 14.0, "color": Color(0.0, 0.73, 0.98), "gem": 5},
}

var radius := 10.0
var hp := 14.0
var speed := 55.0
var contact_damage := 8.0
var color := Color(0.61, 0.36, 0.9)
var gem_value := 1
var target: Node2D

var dead := false
var blade_cd := 0.0

var _flash := 0.0


func setup(kind: String, wave: int, target_node: Node2D) -> void:
	var t: Dictionary = TYPES[kind]
	radius = t["radius"]
	hp = t["hp"] * (1.0 + (wave - 1) * 0.35)
	speed = t["speed"] * (1.0 + (wave - 1) * 0.02)
	contact_damage = t["damage"]
	color = t["color"]
	gem_value = t["gem"]
	target = target_node


func _ready() -> void:
	add_to_group("enemies")


func _process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(0.0, _flash - delta)
	blade_cd = maxf(0.0, blade_cd - delta)
	queue_redraw()

	if target == null or not is_instance_valid(target):
		return
	var to_target := target.position - position
	var dist := to_target.length()
	if dist > 0.001:
		position += to_target / dist * speed * delta
	if dist < radius + 11.0:
		target.hurt(contact_damage)


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.08
	if hp <= 0.0:
		dead = true
		died.emit(position, gem_value)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.WHITE if _flash > 0.0 else color)
	var eye := radius * 0.3
	draw_rect(Rect2(-radius * 0.5, -radius * 0.25, eye, eye), Color(0.05, 0.06, 0.09))
	draw_rect(Rect2(radius * 0.2, -radius * 0.25, eye, eye), Color(0.05, 0.06, 0.09))
