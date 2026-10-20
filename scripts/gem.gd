extends Node2D
## Gem z doświadczeniem (EXP). Gdy gracz podejdzie bliżej niż "magnet",
## gem zaczyna do niego lecieć. Dotknięcie gemu daje EXP.

var value := 1
var player: Node2D

var _pull := false


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.position - position
	var dist := to_player.length()
	if dist < player.magnet:
		_pull = true
	if _pull:
		var speed := 260.0 + maxf(0.0, player.magnet - dist) * 2.0
		position += to_player.normalized() * speed * delta
	if dist < 14.0:
		player.add_xp(value)
		queue_free()


func _draw() -> void:
	var s := 7.0 if value > 1 else 5.0
	var c := Color(0.5, 0.93, 0.6) if value > 1 else Color(0.3, 0.79, 0.94)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0),
	]), c)
