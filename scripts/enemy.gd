extends Node2D
## Zombie. Idzie prosto na gracza i zadaje obrażenia przy dotyku.
## Po śmierci wysyła sygnał "died", a main.gd tworzy w tym miejscu gem.

signal died(pos: Vector2, gem_value: int)

const SPRITE_SCALE := 2.0

## Typy zombie. Aby dodać nowy, dopisz tu wpis (i grafikę w tools/make_sprites.py),
## a potem użyj go w funkcji _spawn_enemy w main.gd.
const TYPES := {
	"man": {
		"radius": 11.0, "hp": 14.0, "speed": 55.0, "damage": 8.0, "gem": 1,
		"texture": preload("res://assets/sprites/zombie_man.png"),
	},
	"woman": {
		"radius": 11.0, "hp": 12.0, "speed": 62.0, "damage": 7.0, "gem": 1,
		"texture": preload("res://assets/sprites/zombie_woman.png"),
	},
	"child": {
		"radius": 9.0, "hp": 7.0, "speed": 78.0, "damage": 6.0, "gem": 1,
		"texture": preload("res://assets/sprites/zombie_child.png"),
	},
	"fat": {
		"radius": 16.0, "hp": 60.0, "speed": 36.0, "damage": 14.0, "gem": 5,
		"texture": preload("res://assets/sprites/zombie_fat.png"),
	},
}

var radius := 10.0
var hp := 14.0
var speed := 55.0
var contact_damage := 8.0
var gem_value := 1
var texture: Texture2D
var target: Node2D

var dead := false
var blade_cd := 0.0

var _flash := 0.0
var _anim := 0.0
var _feet := 16.0
var _sprite: Sprite2D


func setup(kind: String, wave: int, target_node: Node2D) -> void:
	var t: Dictionary = TYPES[kind]
	radius = t["radius"]
	hp = t["hp"] * (1.0 + (wave - 1) * 0.35)
	speed = t["speed"] * (1.0 + (wave - 1) * 0.02)
	contact_damage = t["damage"]
	gem_value = t["gem"]
	texture = t["texture"]
	target = target_node


func _ready() -> void:
	add_to_group("enemies")
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = 2
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_feet = texture.get_height() * SPRITE_SCALE * 0.5
	_anim = randf() * 2.0


func _process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(0.0, _flash - delta)
	blade_cd = maxf(0.0, blade_cd - delta)
	_sprite.modulate = Color(1.0, 0.45, 0.45) if _flash > 0.0 else Color.WHITE

	if target == null or not is_instance_valid(target):
		return
	var to_target := target.position - position
	var dist := to_target.length()
	if dist > 0.001:
		position += to_target / dist * speed * delta
	if absf(to_target.x) > 2.0:
		_sprite.flip_h = to_target.x < 0.0
	_anim += delta * speed / 10.0
	_sprite.frame = int(_anim) % 2
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
	# Cień pod nogami
	draw_set_transform(Vector2(0, _feet - 2.0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, radius * 0.95, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
