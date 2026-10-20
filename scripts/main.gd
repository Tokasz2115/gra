extends Node2D
## Główny skrypt gry: fale wrogów, interfejs, ekran awansu i koniec gry.
## Ten węzeł i interfejs działają także podczas pauzy, a świat gry (world)
## zatrzymuje się. Dzięki temu menu wyboru ulepszeń reaguje na kliknięcia.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const GemScript := preload("res://scripts/gem.gd")
const UpgradesScript := preload("res://scripts/upgrades.gd")

const WAVE_LENGTH := 30.0   # sekundy na jedną falę
const MAX_ENEMIES := 250
const BG_COLOR := Color(0.05, 0.06, 0.09)
const GRID_COLOR := Color(0.09, 0.11, 0.15)

var world: Node2D           # tu żyją gracz, wrogowie, pociski i gemy
var player: Node2D

var time := 0.0
var wave := 1
var kills := 0
var spawn_acc := 0.0
var game_over := false
var current_choices: Array = []

var xp_bar: ProgressBar
var hp_bar: ProgressBar
var info_label: Label
var banner_label: Label
var pause_label: Label
var levelup_panel: PanelContainer
var levelup_title: Label
var cards_box: HBoxContainer
var over_panel: PanelContainer
var over_label: Label
var restart_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	RenderingServer.set_default_clear_color(BG_COLOR)

	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	_build_ui()
	_start_game()


func _start_game() -> void:
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()

	time = 0.0
	wave = 1
	kills = 0
	spawn_acc = 0.0
	game_over = false
	current_choices.clear()
	get_tree().paused = false
	pause_label.hide()
	levelup_panel.hide()
	over_panel.hide()

	player = PlayerScript.new()
	world.add_child(player)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)

	_update_hud()
	_show_banner("Fala 1 - test aktualizacji")


func _process(delta: float) -> void:
	queue_redraw()
	if get_tree().paused or game_over:
		return

	time += delta
	var new_wave := 1 + int(time / WAVE_LENGTH)
	if new_wave != wave:
		wave = new_wave
		_show_banner("Fala %d" % wave)

	spawn_acc += (1.2 + wave * 0.9) * delta
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		if get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
			_spawn_enemy()

	_update_hud()


func _spawn_enemy() -> void:
	var kind := "basic"
	var roll := randf()
	if wave >= 3 and roll < 0.12:
		kind = "tank"
	elif wave >= 2 and roll < 0.38:
		kind = "fast"

	var half := get_viewport_rect().size * 0.5
	var pos := player.position + Vector2.from_angle(randf() * TAU) * (half.length() + 50.0)

	var e = EnemyScript.new()
	e.setup(kind, wave, player)
	e.position = pos
	e.died.connect(_on_enemy_died)
	world.add_child(e)


func _on_enemy_died(pos: Vector2, gem_value: int) -> void:
	kills += 1
	var g = GemScript.new()
	g.position = pos
	g.value = gem_value
	g.player = player
	world.call_deferred("add_child", g)


# ---------- Awans i wybór ulepszeń ----------

func _on_leveled_up() -> void:
	_show_choices()


func _show_choices() -> void:
	get_tree().paused = true

	var pool: Array = []
	for u in UpgradesScript.all():
		var lv: int = player.upgrade_levels.get(u["id"], 0)
		if u["max"] == 0 or lv < u["max"]:
			pool.append(u)
	pool.shuffle()
	current_choices = pool.slice(0, 3)

	for c in cards_box.get_children():
		cards_box.remove_child(c)
		c.queue_free()

	levelup_title.text = "Awans na poziom %d" % player.level
	for i in current_choices.size():
		var u: Dictionary = current_choices[i]
		var lv: int = player.upgrade_levels.get(u["id"], 0)
		var status := "Poziom %d → %d" % [lv, lv + 1] if lv > 0 else "Nowe"
		var b := Button.new()
		b.text = "[%d]  %s\n\n%s\n\n%s" % [i + 1, u["name"], u["desc"], status]
		b.custom_minimum_size = Vector2(190, 170)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_choose.bind(i))
		cards_box.add_child(b)

	levelup_panel.show()
	if cards_box.get_child_count() > 0:
		cards_box.get_child(0).grab_focus()


func _choose(index: int) -> void:
	if index >= current_choices.size():
		return
	player.apply_upgrade(current_choices[index])
	player.pending_levels -= 1
	if player.pending_levels > 0:
		_show_choices()
		return
	levelup_panel.hide()
	get_tree().paused = false
	_update_hud()


# ---------- Koniec gry i pauza ----------

func _on_player_died() -> void:
	game_over = true
	get_tree().paused = true
	over_label.text = "Czas: %s\nFala: %d\nPoziom: %d\nZabici: %d" % [
		_fmt_time(time), wave, player.level, kills
	]
	over_panel.show()
	restart_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and levelup_panel.visible:
		var idx: int = key.keycode - KEY_1
		if idx >= 0 and idx < current_choices.size():
			_choose(idx)
		return
	if event.is_action_pressed("ui_cancel") and not game_over and not levelup_panel.visible:
		var p := not get_tree().paused
		get_tree().paused = p
		pause_label.visible = p


# ---------- Interfejs ----------

func _update_hud() -> void:
	xp_bar.max_value = player.need
	xp_bar.value = player.xp
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	info_label.text = "Poziom %d     Fala %d     Czas %s     Zabici %d" % [
		player.level, wave, _fmt_time(time), kills
	]


func _fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]


func _show_banner(text: String) -> void:
	banner_label.text = text
	banner_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.8)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Pasek na górze: EXP, HP i statystyki
	var top := VBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(0, 12)
	xp_bar.modulate = Color(0.3, 0.79, 0.94)
	top.add_child(xp_bar)

	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, 8)
	hp_bar.modulate = Color(0.94, 0.28, 0.44)
	top.add_child(hp_bar)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(info_label)

	# Środek ekranu: baner fali, pauza, wybór ulepszeń, koniec gry
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	banner_label = Label.new()
	banner_label.add_theme_font_size_override("font_size", 48)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.71, 0.33))
	banner_label.modulate.a = 0.0
	center.add_child(banner_label)

	pause_label = Label.new()
	pause_label.text = "PAUZA\n(Esc, aby wznowić)"
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 36)
	pause_label.hide()
	center.add_child(pause_label)

	levelup_panel = PanelContainer.new()
	levelup_panel.hide()
	center.add_child(levelup_panel)
	var lv_margin := _margin_box(levelup_panel)
	var lv_box := VBoxContainer.new()
	lv_box.add_theme_constant_override("separation", 14)
	lv_margin.add_child(lv_box)
	levelup_title = Label.new()
	levelup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	levelup_title.add_theme_font_size_override("font_size", 28)
	lv_box.add_child(levelup_title)
	var hint := Label.new()
	hint.text = "Wybierz ulepszenie kliknięciem albo klawiszem 1, 2 lub 3"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_box.add_child(hint)
	cards_box = HBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 12)
	lv_box.add_child(cards_box)

	over_panel = PanelContainer.new()
	over_panel.hide()
	center.add_child(over_panel)
	var over_margin := _margin_box(over_panel)
	var over_box := VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 14)
	over_margin.add_child(over_box)
	var over_title := Label.new()
	over_title.text = "Koniec gry"
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_title.add_theme_font_size_override("font_size", 32)
	over_box.add_child(over_title)
	over_label = Label.new()
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(over_label)
	restart_button = Button.new()
	restart_button.text = "Zagraj ponownie"
	restart_button.pressed.connect(_start_game)
	over_box.add_child(restart_button)


func _margin_box(parent: Control) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(side, 20)
	parent.add_child(m)
	return m


# ---------- Tło: siatka wokół gracza ----------

func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var cell := 64.0
	var half := get_viewport_rect().size * 0.5 + Vector2(cell, cell)
	var c := player.position
	var x := floorf((c.x - half.x) / cell) * cell
	while x <= c.x + half.x:
		draw_line(Vector2(x, c.y - half.y), Vector2(x, c.y + half.y), GRID_COLOR)
		x += cell
	var y := floorf((c.y - half.y) / cell) * cell
	while y <= c.y + half.y:
		draw_line(Vector2(c.x - half.x, y), Vector2(c.x + half.x, y), GRID_COLOR)
		y += cell
