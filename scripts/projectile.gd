extends Node2D
## Pocisk lecący prosto. Zadaje obrażenia pierwszemu trafionemu wrogowi,
## a potem leci dalej, jeśli ma jeszcze "pierce" (przebicie).

var velocity := Vector2.ZERO
var damage := 10.0
var pierce := 0
var life := 1.3

var _hit: Array = []


func _process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or e in _hit:
			continue
		var reach: float = e.radius + 4.0
		if position.distance_squared_to(e.position) < reach * reach:
			e.take_damage(damage)
			_hit.append(e)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.71, 0.33))
