extends Node2D
## Gem z doświadczeniem (EXP). Gdy gracz podejdzie bliżej niż "magnet",
## gem zaczyna do niego lecieć. Dotknięcie gemu daje EXP.

var value := 1
var player: Node2D

var _pull := false
var _t := randf() * TAU


func _process(delta: float) -> void:
	_t += delta * 5.0
	scale = Vector2.ONE * (1.0 + 0.1 * sin(_t))
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
	var big := value > 1
	var s := 9.0 if big else 7.0
	var base := Color(1.0, 0.3, 0.85) if big else Color(0.1, 0.85, 1.0)
	var light := Color(1.0, 0.85, 1.0) if big else Color(0.8, 1.0, 1.0)
	var dark := Color(0.5, 0.05, 0.45) if big else Color(0.0, 0.4, 0.7)
	# Poświata
	draw_circle(Vector2.ZERO, s + 5.0, Color(base.r, base.g, base.b, 0.25))
	var top := Vector2(0, -s)
	var right := Vector2(s * 0.8, 0)
	var bottom := Vector2(0, s)
	var left := Vector2(-s * 0.8, 0)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), base)
	draw_colored_polygon(PackedVector2Array([top, left, Vector2(0, -s * 0.1)]), light)
	draw_colored_polygon(PackedVector2Array([bottom, right, Vector2(0, s * 0.1)]), dark)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), Color(0.04, 0.04, 0.1), 2.0)
