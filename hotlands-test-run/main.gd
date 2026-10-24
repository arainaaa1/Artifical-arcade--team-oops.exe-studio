extends Node2D

const PlayerScript = preload("res://player.gd")
const PillarScript = preload("res://movable_pillar.gd")
const CRT_SHADER: Shader = preload("res://assets/shaders/crt_overlay.gdshader")
const SFX_STREAMS: Dictionary = {
	"jump": preload("res://assets/audio/jump.wav"),
	"gravity_flip": preload("res://assets/audio/gravity_flip.wav"),
	"time_slow": preload("res://assets/audio/time_slow.wav"),
	"time_resume": preload("res://assets/audio/time_resume.wav"),
	"object_move": preload("res://assets/audio/object_move.wav"),
	"switch": preload("res://assets/audio/switch.wav"),
	"portal": preload("res://assets/audio/portal.wav"),
	"death_fahhh": preload("res://assets/audio/death_fahhh_meme.mp3"),
	"win_wacky": preload("res://assets/audio/win_wacky.wav"),
}

@export var level_number := 1

var player: CharacterBody2D
var pillar: CharacterBody2D
var second_pillar: CharacterBody2D
var relay_bar_a: CharacterBody2D
var relay_bar_b: CharacterBody2D
var relay_sliders: Array[CharacterBody2D] = []
var relay_targets: Array[Vector2] = []
var portal_cooldown_ms := 450
var switch_pressed := false
var exit_open := false
var completed := false
var status_label: Label
var instruction_panel: ColorRect
var instruction_title: Label
var instruction_toggle: Button
var instructions_collapsed := false
var full_instruction_title := ""
var gravity_label: Label
var energy_bar: ProgressBar
var timer_label: Label
var score_label: Label
var deaths_label: Label
var victory_overlay: Control
var victory_title_label: Label
var victory_result_label: Label
var exit_door_shape: CollisionShape2D
var exit_door_visual: ColorRect
var exit_portal: ColorRect
var freeze_remaining := 3.0
var freeze_active := false
var final_rail_b_unlocked := false
var final_rail_c_unlocked := false
var sfx_players: Dictionary = {}
var death_in_progress := false

func _ready() -> void:
	RunStats.begin_level(level_number)
	_build_audio()
	_setup_input()
	_build_room()
	_build_ui()
	_build_crt_overlay()

func _build_audio() -> void:
	for sound_name in SFX_STREAMS:
		var audio_player := AudioStreamPlayer.new()
		audio_player.name = "SFX_" + sound_name
		audio_player.stream = SFX_STREAMS[sound_name]
		audio_player.volume_db = -2.0 if sound_name != "death_fahhh" else -5.0
		add_child(audio_player)
		sfx_players[sound_name] = audio_player

func _play_sfx(sound_name: String) -> void:
	var audio_player := sfx_players.get(sound_name) as AudioStreamPlayer
	if audio_player == null:
		return
	audio_player.stop()
	audio_player.play()

func _setup_input() -> void:
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("jump", KEY_SPACE)
	_add_key("gravity_flip", KEY_Q)
	_add_key("pull_object", KEY_E)
	_add_key("push_object", KEY_R)
	_add_key("freeze_time", KEY_F)
	_add_key("restart_test", KEY_ENTER)

func _add_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _build_room() -> void:
	# Enclosed training chamber, with a central pit and a small raised route.
	_add_background()
	var exit_position := Vector2(1030, 460)
	var second_switch_position := Vector2(970, 494)
	if level_number == 3:
		# Split ceiling: gravity walkers cannot bypass the puzzle across the whole room.
		_add_platform(Vector2(150, 18), Vector2(300, 36), Color("8a2be2"))
		_add_platform(Vector2(950, 18), Vector2(300, 36), Color("8a2be2"))
	else:
		_add_platform(Vector2(550, 18), Vector2(1100, 36), Color("8a2be2"))
	_add_platform(Vector2(18, 294), Vector2(36, 588), Color("8a2be2"))
	_add_platform(Vector2(1082, 294), Vector2(36, 588), Color("8a2be2"))
	var switch_x := 792.0
	var switch_y := 494.0
	var pillar_start := Vector2(330, 452)
	var player_start := Vector2(100, 460)
	if level_number == 1:
		_add_platform(Vector2(222, 515), Vector2(284, 24), Color("8a2be2"))
		_add_platform(Vector2(878, 515), Vector2(444, 24), Color("8a2be2"))
		_add_platform(Vector2(474, 398), Vector2(140, 18), Color("ff0033"))
		_add_platform(Vector2(790, 320), Vector2(128, 18), Color("ff0033"))
		_add_platform(Vector2(1000, 430), Vector2(100, 18), Color("ff0033"))
	elif level_number == 2:
		switch_x = 920.0
		pillar_start = Vector2(280, 452)
		_add_platform(Vector2(200, 515), Vector2(240, 24), Color("8a2be2"))
		_add_platform(Vector2(880, 515), Vector2(440, 24), Color("8a2be2"))
		_add_platform(Vector2(395, 425), Vector2(118, 18), Color("ff0033"))
		_add_platform(Vector2(560, 330), Vector2(130, 18), Color("ff0033"))
		_add_platform(Vector2(725, 420), Vector2(112, 18), Color("ff0033"))
		_add_platform(Vector2(955, 350), Vector2(112, 18), Color("ff0033"))
	elif level_number == 3:
		switch_x = 850.0
		switch_y = 382.0
		pillar_start = Vector2(250, 452)
		_add_platform(Vector2(180, 515), Vector2(200, 24), Color("8a2be2"))
		_add_platform(Vector2(910, 515), Vector2(380, 24), Color("8a2be2"))
		_add_platform(Vector2(850, 410), Vector2(190, 20), Color("8a2be2"))
		_add_platform(Vector2(400, 420), Vector2(110, 18), Color("ff0033"))
		_add_platform(Vector2(650, 300), Vector2(110, 18), Color("ff0033"))
		_add_platform(Vector2(1000, 300), Vector2(110, 18), Color("ff0033"))
		# Movable concrete pillars sit on the stepping platforms and can be pushed aside.
	elif level_number == 4:
		switch_x = 930.0
		switch_y = 494.0
		pillar_start = Vector2(220, 472)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		# Two captive sliders must be parked at opposite ends to route power to the plate.
		_add_relay_dock(Vector2(300, 405), "A")
		_add_relay_dock(Vector2(930, 405), "B")
	elif level_number == 5:
		switch_x = 930.0
		switch_y = 494.0
		pillar_start = Vector2(220, 472)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		_add_route_rail(true, 345.0, 300.0, 850.0, "A", 350.0)
		_add_route_rail(true, 430.0, 300.0, 850.0, "B", 850.0)
		_add_route_rail(false, 470.0, 225.0, 430.0, "C", 390.0)
		_add_route_rail(false, 800.0, 225.0, 430.0, "D", 225.0)
		for junction in [Vector2(470, 345), Vector2(800, 345), Vector2(470, 430), Vector2(800, 430)]:
			_make_rect(junction, Vector2(13, 13), Color("00ff33"))
	elif level_number == 6:
		switch_x = 950.0
		switch_y = 494.0
		pillar_start = Vector2(260, 472)
		_add_platform(Vector2(550, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		_add_portal_pair(Vector2(522, 455), Vector2(578, 455))
	elif level_number == 7:
		switch_x = 960.0
		switch_y = 494.0
		pillar_start = Vector2(100, 148)
		player_start = Vector2(55, 142)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		# Maze walls make the box route through two linked portal pairs.
		_add_platform(Vector2(260, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(550, 180), Vector2(32, 324), Color("8a2be2"))
		_add_platform(Vector2(820, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(130, 190), Vector2(260, 20), Color("ff0033"))
		_add_route_rail(true, 460.0, 365.0, 500.0, "A", 365.0)
		_add_route_rail(true, 460.0, 600.0, 720.0, "B", 700.0)
		_add_portal_pair(Vector2(238, 150), Vector2(410, 440))
		_add_portal_pair(Vector2(798, 460), Vector2(842, 460))
	elif level_number == 8:
		switch_x = 1000.0
		switch_y = 494.0
		pillar_start = Vector2(100, 148)
		player_start = Vector2(55, 142)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		# Four maze partitions create a three-transfer route; the tall middle wall forces a lower detour.
		_add_platform(Vector2(220, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(470, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(610, 180), Vector2(32, 324), Color("8a2be2"))
		_add_platform(Vector2(750, 294), Vector2(32, 552), Color("8a2be2"))
		_add_platform(Vector2(130, 190), Vector2(220, 20), Color("ff0033"))
		_add_route_rail(true, 460.0, 350.0, 400.0, "A", 400.0)
		_add_route_rail(true, 460.0, 600.0, 700.0, "B", 650.0)
		_add_route_rail(false, 900.0, 300.0, 460.0, "C", 320.0)
		_add_portal_pair(Vector2(198, 150), Vector2(250, 430))
		_add_portal_pair(Vector2(448, 460), Vector2(492, 460))
		_add_portal_pair(Vector2(728, 460), Vector2(772, 460))
	elif level_number == 9:
		# Dual-circuit chamber: the player and both boxes start between two gated side lanes.
		switch_x = 130.0
		switch_y = 494.0
		pillar_start = Vector2(490, 472)
		player_start = Vector2(550, 472)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		# These partitions leave broad lower tunnels, so the boxes can pass once each gate is parked clear.
		_add_platform(Vector2(340, 210), Vector2(32, 360), Color("8a2be2"))
		_add_platform(Vector2(760, 210), Vector2(32, 360), Color("8a2be2"))
		_make_rect(Vector2(130, 497), Vector2(170, 12), Color("ffff00"))
		_make_rect(Vector2(970, 497), Vector2(170, 12), Color("8a2be2"))
		_add_route_rail(true, 420.0, 220.0, 350.0, "A", 220.0)
		_add_route_rail(true, 420.0, 750.0, 880.0, "B", 880.0)
		var left_target := Label.new()
		left_target.text = "GREEN -> LEFT"
		left_target.position = Vector2(60, 400)
		left_target.add_theme_color_override("font_color", Color("00ff33"))
		left_target.add_theme_font_size_override("font_size", 14)
		add_child(left_target)
		var right_target := Label.new()
		right_target.text = "RED -> RIGHT"
		right_target.position = Vector2(870, 400)
		right_target.add_theme_color_override("font_color", Color("ff0033"))
		right_target.add_theme_font_size_override("font_size", 14)
		add_child(right_target)
	else:
		# Roomy final ascent: each shelf has box-width routes, with over 100 px
		# of vertical clearance between tiers for the tall movable boxes.
		switch_x = 250.0
		switch_y = 119.0
		second_switch_position = Vector2(850, 119)
		exit_position = Vector2(550, 92)
		player_start = Vector2(110, 465)
		pillar_start = Vector2(230, 455)
		_add_platform(Vector2(550, 515), Vector2(1050, 24), Color("8a2be2"))
		# Lower shelf has two 120 px openings; the next shelf has one 180 px opening.
		_add_platform(Vector2(208, 385), Vector2(344, 16), Color("8a2be2"))
		_add_platform(Vector2(550, 385), Vector2(100, 16), Color("8a2be2"))
		_add_platform(Vector2(892, 385), Vector2(344, 16), Color("8a2be2"))
		_add_platform(Vector2(318, 255), Vector2(564, 16), Color("8a2be2"))
		_add_platform(Vector2(922, 255), Vector2(284, 16), Color("8a2be2"))
		# The summit pads are lowered slightly so an 82 px box fits below the ceiling.
		_add_platform(Vector2(250, 135), Vector2(220, 16), Color("ffff00"))
		_add_platform(Vector2(850, 135), Vector2(220, 16), Color("8a2be2"))
		_add_route_rail(true, 385.0, 250.0, 440.0, "A", 300.0)
		_add_route_rail(true, 385.0, 660.0, 850.0, "B", 850.0)
		_add_route_rail(true, 255.0, 560.0, 850.0, "C", 850.0)
		_make_rect(Vector2(250, 117), Vector2(70, 8), Color("00ff33"))
		_make_rect(Vector2(850, 117), Vector2(70, 8), Color("8a2be2"))
		var summit_label := Label.new()
		summit_label.text = "GREEN CORE PLATE                 RED CORE PLATE"
		summit_label.position = Vector2(170, 150)
		summit_label.add_theme_color_override("font_color", Color("ffffff"))
		summit_label.add_theme_font_size_override("font_size", 14)
		add_child(summit_label)

	# Hazard pit at the bottom of the gap. Gravity reversal provides the safe route.
	if level_number < 4:
		_add_spike_hazard(Vector2(550, 545), Vector2(148, 26), "PitHazard")
	if level_number == 2:
		_add_spike_hazard(Vector2(740, 501), Vector2(72, 18), "CorridorHazard")
	elif level_number == 3:
		_add_spike_hazard(Vector2(640, 545), Vector2(120, 22), "DropZoneHazard")
		_add_platform(Vector2(550, 580), Vector2(300, 16), Color("8a2be2"))

	pillar = _create_movable_pillar("SilverBox", pillar_start)
	if level_number == 5 or level_number == 7 or level_number == 8 or level_number == 9 or level_number == 10:
		# The routed beams are solid to the green box and player (layer 2).
		pillar.collision_mask = 3
	if level_number == 9 or level_number == 10:
		var amber_start := Vector2(600, 472) if level_number == 9 else Vector2(330, 455)
		second_pillar = _create_movable_pillar("AmberBox", amber_start)
		second_pillar.collision_mask = 3
	if level_number == 3:
		_create_movable_pillar("ConcretePillarA", Vector2(400, 357))
		_create_movable_pillar("ConcretePillarB", Vector2(650, 237))
	elif level_number == 4:
		relay_bar_a = _create_movable_pillar("HorizontalPillarA", Vector2(510, 405), Vector2(130, 26))
		relay_bar_b = _create_movable_pillar("HorizontalPillarB", Vector2(740, 405), Vector2(130, 26))
		for bar in [relay_bar_a, relay_bar_b]:
			bar.set("horizontal_track", true)
			bar.set("track_y", 405.0)
		relay_bar_a.set("track_min_x", 300.0)
		relay_bar_a.set("track_max_x", 650.0)
		relay_bar_b.set("track_min_x", 580.0)
		relay_bar_b.set("track_max_x", 930.0)
		relay_sliders = [relay_bar_a, relay_bar_b]
		relay_targets = [Vector2(300, 405), Vector2(930, 405)]
	elif level_number == 5:
		relay_sliders.append(_create_track_slider("RouterA", Vector2(750, 345), Vector2(130, 26), true, 300.0, 850.0, 345.0))
		relay_sliders.append(_create_track_slider("RouterB", Vector2(400, 430), Vector2(130, 26), true, 300.0, 850.0, 430.0))
		relay_sliders.append(_create_track_slider("RouterC", Vector2(470, 225), Vector2(26, 96), false, 225.0, 430.0, 470.0))
		relay_sliders.append(_create_track_slider("RouterD", Vector2(800, 430), Vector2(26, 96), false, 225.0, 430.0, 800.0))
		relay_targets = [Vector2(350, 345), Vector2(850, 430), Vector2(470, 390), Vector2(800, 225)]
	elif level_number == 7:
		relay_sliders.append(_create_track_slider("MazeRailA", Vector2(450, 460), Vector2(150, 26), true, 365.0, 500.0, 460.0))
		relay_sliders.append(_create_track_slider("MazeRailB", Vector2(680, 460), Vector2(150, 26), true, 600.0, 720.0, 460.0))
		relay_targets = [Vector2(365, 460), Vector2(700, 460)]
	elif level_number == 8:
		relay_sliders.append(_create_track_slider("MazeRailA", Vector2(350, 460), Vector2(100, 26), true, 350.0, 400.0, 460.0))
		relay_sliders.append(_create_track_slider("MazeRailB", Vector2(620, 460), Vector2(100, 26), true, 600.0, 700.0, 460.0))
		relay_sliders.append(_create_track_slider("MazeRailC", Vector2(900, 440), Vector2(26, 100), false, 300.0, 440.0, 900.0))
		relay_targets = [Vector2(400, 460), Vector2(650, 460), Vector2(900, 320)]
	elif level_number == 9:
		relay_sliders.append(_create_track_slider("DualRailA", Vector2(340, 420), Vector2(80, 22), true, 220.0, 350.0, 420.0))
		relay_sliders.append(_create_track_slider("DualRailB", Vector2(760, 420), Vector2(80, 22), true, 750.0, 880.0, 420.0))
		relay_targets = [Vector2(220, 420), Vector2(880, 420)]
	elif level_number == 10:
		relay_sliders.append(_create_track_slider("FinalRailA", Vector2(440, 385), Vector2(100, 16), true, 250.0, 440.0, 385.0))
		relay_sliders.append(_create_track_slider("FinalRailB", Vector2(660, 385), Vector2(100, 16), true, 660.0, 850.0, 385.0))
		# This rail nearly fills the 180 px upper opening at its start, so the boxes cannot bypass it.
		relay_sliders.append(_create_track_slider("FinalRailC", Vector2(690, 255), Vector2(140, 16), true, 690.0, 850.0, 255.0))
		relay_targets = [Vector2(300, 385), Vector2(850, 385), Vector2(850, 255)]
		relay_sliders[1].set("drag_locked", true)
		relay_sliders[2].set("drag_locked", true)

	# Pressure switch; the heavy pillar must be pulled onto this plate.
	var switch_area := Area2D.new()
	switch_area.name = "PressureSwitch"
	switch_area.position = Vector2(switch_x, switch_y)
	switch_area.add_to_group("switch")
	var switch_shape := CollisionShape2D.new()
	var switch_rect := RectangleShape2D.new()
	switch_rect.size = Vector2(70, 20)
	switch_shape.shape = switch_rect
	switch_area.add_child(switch_shape)
	add_child(switch_area)
	var switch_visual := _make_rect(Vector2(switch_x, switch_y - 2), Vector2(70, 8), Color("ffff00"))
	switch_visual.name = "SwitchPlate"
	if level_number == 10:
		switch_visual.color = Color("00ff33")
	var second_switch_area: Area2D
	var second_switch_visual: ColorRect
	if level_number == 9 or level_number == 10:
		second_switch_area = Area2D.new()
		second_switch_area.name = "SecondPressureSwitch"
		second_switch_area.position = second_switch_position
		var second_switch_shape := CollisionShape2D.new()
		var second_switch_rect := RectangleShape2D.new()
		second_switch_rect.size = Vector2(70, 20)
		second_switch_shape.shape = second_switch_rect
		second_switch_area.add_child(second_switch_shape)
		add_child(second_switch_area)
		second_switch_visual = _make_rect(second_switch_position + Vector2(0, -2), Vector2(70, 8), Color("8a2be2"))
		second_switch_visual.name = "SecondSwitchPlate"

	# Exit door starts locked and opens when the plate is held down.
	var door := StaticBody2D.new()
	door.name = "ExitDoor"
	door.position = exit_position
	exit_door_shape = CollisionShape2D.new()
	var door_shape := RectangleShape2D.new()
	door_shape.size = Vector2(34, 112)
	exit_door_shape.shape = door_shape
	door.add_child(exit_door_shape)
	exit_door_visual = ColorRect.new()
	exit_door_visual.position = Vector2(-17, -56)
	exit_door_visual.size = Vector2(34, 112)
	exit_door_visual.color = Color("ff0033")
	door.add_child(exit_door_visual)
	add_child(door)
	exit_portal = _make_rect(exit_position, Vector2(18, 92), Color("00ff33"))
	exit_portal.visible = false
	var exit_area := Area2D.new()
	exit_area.name = "Exit"
	exit_area.position = exit_position + Vector2(0, 24)
	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()
	exit_rect.size = Vector2(70, 100)
	exit_shape.shape = exit_rect
	exit_area.add_child(exit_shape)
	add_child(exit_area)
	exit_area.body_entered.connect(_on_exit_body_entered)

	player = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	player.z_index = 10
	if level_number == 5 or level_number == 7 or level_number == 8 or level_number == 9 or level_number == 10:
		player.collision_mask = 3
	player.position = player_start
	add_child(player)
	player.gravity_changed.connect(_on_gravity_changed)
	player.jumped.connect(_on_player_jumped)
	player.object_manipulated.connect(_on_player_object_manipulated)
	player.object_drag_started.connect(_on_player_drag_started)
	player.died.connect(_on_player_died)

	# Track switch overlap for either the player or the movable pillar.
	switch_area.body_entered.connect(_check_switch)
	switch_area.body_exited.connect(_check_switch)
	if second_switch_area != null:
		second_switch_area.body_entered.connect(_check_switch)
		second_switch_area.body_exited.connect(_check_switch)
	set_meta("exit_area", exit_area)
	set_meta("switch_area", switch_area)
	set_meta("switch_visual", switch_visual)
	if second_switch_area != null:
		set_meta("second_switch_area", second_switch_area)
		set_meta("second_switch_visual", second_switch_visual)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	instruction_panel = ColorRect.new()
	instruction_panel.name = "InstructionPanel"
	instruction_panel.color = Color(0.0, 0.0, 0.0, 0.78)
	instruction_panel.position = Vector2(20, 18)
	instruction_panel.size = Vector2(610, 144)
	layer.add_child(instruction_panel)
	instruction_title = Label.new()
	var level_title := "TRAINING BAY" if level_number == 1 else "CRUSHING CORRIDOR" if level_number == 2 else "INVERTED DROP LAB" if level_number == 3 else "HORIZONTAL RELAY" if level_number == 4 else "CROSSROUTER" if level_number == 5 else "PORTAL TUTORIAL" if level_number == 6 else "TELEPORT MAZE" if level_number == 7 else "SYSTEMS MAZE" if level_number == 8 else "DUAL-CIRCUIT MAZE" if level_number == 9 else "FINAL ASCENT"
	full_instruction_title = "S%02d | %s" % [level_number, level_title]
	instruction_title.text = full_instruction_title
	instruction_title.position = Vector2(36, 25)
	instruction_title.add_theme_color_override("font_color", Color("00ff33"))
	instruction_title.add_theme_font_size_override("font_size", 14)
	layer.add_child(instruction_title)
	status_label = Label.new()
	status_label.text = "A/D OR LEFT/RIGHT: MOVE | SPACE: JUMP\nQ: FLIP GRAVITY | E: PULL | R: PUSH\nHOLD F: " + ("SLOW YOU + OBJECTS" if level_number == 3 else "FREEZE (3 SEC)") + "\nMOUSE: CLICK + DRAG A BOX (2.5 SEC)"
	status_label.position = Vector2(36, 54)
	status_label.size = Vector2(580, 82)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(status_label)
	gravity_label = Label.new()
	gravity_label.text = "GRAVITY DOWN"
	gravity_label.position = Vector2(440, 28)
	gravity_label.add_theme_color_override("font_color", Color("00ff33"))
	gravity_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(gravity_label)
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(440, 61)
	energy_bar.size = Vector2(128, 16)
	energy_bar.min_value = 0
	energy_bar.max_value = 3
	energy_bar.value = 3
	energy_bar.show_percentage = false
	var meter_background := StyleBoxFlat.new()
	meter_background.bg_color = Color("000000")
	meter_background.border_color = Color("8a2be2")
	meter_background.border_width_left = 2
	meter_background.border_width_top = 2
	meter_background.border_width_right = 2
	meter_background.border_width_bottom = 2
	energy_bar.add_theme_stylebox_override("background", meter_background)
	var meter_fill := StyleBoxFlat.new()
	meter_fill.bg_color = Color("00ff33")
	energy_bar.add_theme_stylebox_override("fill", meter_fill)
	layer.add_child(energy_bar)
	instruction_toggle = Button.new()
	instruction_toggle.name = "MinimizeInstructionsButton"
	instruction_toggle.text = "-"
	instruction_toggle.position = Vector2(582, 21)
	instruction_toggle.size = Vector2(30, 28)
	instruction_toggle.tooltip_text = "Minimize the instructions panel"
	instruction_toggle.add_theme_font_size_override("font_size", 14)
	_style_horror_button(instruction_toggle)
	instruction_toggle.pressed.connect(_toggle_instructions)
	layer.add_child(instruction_toggle)
	var hint := Label.new()
	var room_hint := "PULL PILLAR TO PLATE  ->  EXIT" if level_number == 1 else "TWO HAZARDS  |  FAR SWITCH  ->  EXIT" if level_number == 2 else "DRAG BOX ONTO YELLOW PLATE\nQ LIFTS  |  F SLOWS YOU + OBJECTS" if level_number == 3 else "HORIZONTAL RELAY\nSLIDE EACH BAR ALONG ITS RAIL TO THE MATCHING END DOCK. THEN PUT THE BOX ON THE PLATE." if level_number == 4 else "CROSSROUTER\nTrace the neon-green junctions and park all four matching relays. Then place the box on the plate." if level_number == 5 else "PORTAL TEST\nWalk into a portal. Drag the green box into it too, then put it on the plate." if level_number == 6 else "TELEPORT MAZE\nTake the box through both portal pairs. Park both rail gates, then reach the bottom-right plate." if level_number == 7 else "SYSTEMS MAZE\nPark A and B at their docks. Route the box through 3 portal pairs, lift rail C, then reach the final plate." if level_number == 8 else "DUAL-CIRCUIT\nStart in the center. Park A left and B right to clear the tunnels. Push green through the left route and red through the right; both plates open the exit." if level_number == 9 else "FINAL ASCENT\nSlide A out of the first gap and rise through it with Q. Reaching the middle tier unlocks B; park A and B to unlock C. The widened shelves leave room for both boxes to pass to their separate summit plates."
	hint.text = room_hint
	hint.position = Vector2(660, 28)
	hint.size = Vector2(420, 130)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("ffff00"))
	hint.add_theme_font_size_override("font_size", 14)
	layer.add_child(hint)
	if level_number == 8 or level_number == 10:
		var reset_button := Button.new()
		reset_button.text = "RESET LEVEL"
		reset_button.position = Vector2(900, 166)
		reset_button.size = Vector2(160, 38)
		reset_button.tooltip_text = "Restart this level from the beginning"
		_style_horror_button(reset_button)
		reset_button.pressed.connect(_on_reset_level_pressed)
		layer.add_child(reset_button)
	var performance_panel := ColorRect.new()
	performance_panel.name = "TimerAndScorePanel"
	performance_panel.position = Vector2(20, 532)
	performance_panel.size = Vector2(460, 42)
	performance_panel.color = Color(0.0, 0.0, 0.0, 0.84)
	performance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(performance_panel)
	timer_label = _make_performance_label("TIME " + RunStats.formatted_time(), Vector2(32, 541), Color("ffffff"), 140)
	timer_label.name = "RunTimerLabel"
	layer.add_child(timer_label)
	score_label = _make_performance_label("SCORE %04d" % RunStats.current_level_score(), Vector2(180, 541), Color("00ff33"), 140)
	score_label.name = "LevelScoreLabel"
	layer.add_child(score_label)
	deaths_label = _make_performance_label("DEATHS %d" % RunStats.deaths, Vector2(328, 541), Color("ff0033"), 140)
	deaths_label.name = "DeathsLabel"
	layer.add_child(deaths_label)

	victory_overlay = Control.new()
	victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_overlay.visible = false
	layer.add_child(victory_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.86)
	victory_overlay.add_child(shade)
	var card := ColorRect.new()
	card.position = Vector2(270, 180)
	card.size = Vector2(560, 290)
	card.color = Color("000000")
	victory_overlay.add_child(card)
	victory_title_label = Label.new()
	var clear_title := "TUTORIAL CLEARED" if level_number == 1 else "CRUSHING CORRIDOR CLEARED" if level_number == 2 else "INVERTED DROP LAB CLEARED" if level_number == 3 else "HORIZONTAL RELAY CLEARED" if level_number == 4 else "CROSSROUTER CLEARED" if level_number == 5 else "PORTAL TEST CLEARED" if level_number == 6 else "TELEPORT MAZE CLEARED" if level_number == 7 else "SYSTEMS MAZE CLEARED" if level_number == 8 else "DUAL-CIRCUIT MAZE CLEARED" if level_number == 9 else "FINAL ASCENT CLEARED"
	victory_title_label.text = clear_title
	victory_title_label.position = Vector2(295, 215)
	victory_title_label.size = Vector2(510, 24)
	victory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title_label.add_theme_color_override("font_color", Color("00ff33"))
	victory_title_label.add_theme_font_size_override("font_size", 14)
	victory_overlay.add_child(victory_title_label)
	victory_result_label = Label.new()
	if level_number == 1:
		victory_result_label.text = "Tutorial clear! You used gravity, object control, and time freeze.\n\nPress ENTER to continue to the harder level."
	elif level_number == 2:
		victory_result_label.text = "Crushing Corridor cleared!\n\nPress ENTER to replay this level."
	elif level_number == 3:
		victory_result_label.text = "You timed the box drop and navigated the pillars.\n\nPress ENTER to continue to level 4."
	elif level_number == 4:
		victory_result_label.text = "Relay aligned!\n\nPress ENTER to continue to the Crossrouter."
	elif level_number == 5:
		victory_result_label.text = "Crossrouter cleared!\n\nPress ENTER to continue to the portal tutorial."
	elif level_number == 6:
		victory_result_label.text = "Portal transfer confirmed!\n\nPress ENTER to enter the Teleport Maze."
	elif level_number == 7:
		victory_result_label.text = "Maze escaped!\n\nPress ENTER to enter the Systems Maze."
	elif level_number == 8:
		victory_result_label.text = "Systems Maze escaped!\n\nPress ENTER to enter the Dual-Circuit Maze."
	elif level_number == 9:
		victory_result_label.text = "Both circuits aligned!\n\nPress ENTER to replay the Dual-Circuit Maze."
	else:
		victory_result_label.text = "You stabilized both circuits and escaped the final collapse!\n\nPress ENTER to replay the final level."
	victory_result_label.position = Vector2(315, 270)
	victory_result_label.size = Vector2(480, 180)
	victory_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	victory_result_label.add_theme_font_size_override("font_size", 14)
	victory_overlay.add_child(victory_result_label)

func _make_performance_label(text_value: String, label_position: Vector2, color: Color, label_width: float) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = label_position
	label.size = Vector2(label_width, 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _toggle_instructions() -> void:
	instructions_collapsed = not instructions_collapsed
	status_label.visible = not instructions_collapsed
	if instructions_collapsed:
		instruction_panel.size = Vector2(300, 86)
		instruction_title.text = "LEVEL %02d INFO" % level_number
		instruction_title.add_theme_font_size_override("font_size", 14)
		gravity_label.position = Vector2(36, 55)
		energy_bar.position = Vector2(210, 55)
		energy_bar.size = Vector2(64, 16)
		instruction_toggle.text = "+"
		instruction_toggle.position = Vector2(284, 22)
		instruction_toggle.tooltip_text = "Show the instructions panel"
	else:
		instruction_panel.size = Vector2(610, 144)
		instruction_title.text = full_instruction_title
		instruction_title.add_theme_font_size_override("font_size", 14)
		gravity_label.position = Vector2(440, 28)
		energy_bar.position = Vector2(440, 61)
		energy_bar.size = Vector2(128, 16)
		instruction_toggle.text = "-"
		instruction_toggle.position = Vector2(582, 21)
		instruction_toggle.tooltip_text = "Minimize the instructions panel"


func _style_horror_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("000000")
	normal.border_color = Color("8a2be2")
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	var hovered := normal.duplicate() as StyleBoxFlat
	hovered.border_color = Color("00ff33")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("ff0033")
	pressed.border_color = Color("ffff00")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hovered)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("ffff00"))
	button.add_theme_color_override("font_hover_color", Color("00ff33"))
	button.add_theme_color_override("font_pressed_color", Color("000000"))

func _process(delta: float) -> void:
	if completed:
		if Input.is_action_just_pressed("restart_test"):
			if level_number == 1:
				get_tree().change_scene_to_file("res://level_2.tscn")
			elif level_number == 2:
				get_tree().change_scene_to_file("res://level_3.tscn")
			elif level_number == 3:
				get_tree().change_scene_to_file("res://level_4.tscn")
			elif level_number == 4:
				get_tree().change_scene_to_file("res://level_5.tscn")
			elif level_number == 5:
				get_tree().change_scene_to_file("res://level_6.tscn")
			elif level_number == 6:
				get_tree().change_scene_to_file("res://level_7.tscn")
			elif level_number == 7:
				get_tree().change_scene_to_file("res://level_8.tscn")
			elif level_number == 8:
				get_tree().change_scene_to_file("res://level_9.tscn")
			elif level_number == 9:
				get_tree().change_scene_to_file("res://level_10.tscn")
			elif level_number == 10:
				get_tree().change_scene_to_file("res://title_screen.tscn")
			else:
				RunStats.begin_level(level_number, true)
				get_tree().reload_current_scene()
		return
	RunStats.advance_time(delta)
	timer_label.text = "TIME " + RunStats.formatted_time()
	score_label.text = "SCORE %04d" % RunStats.current_level_score()
	deaths_label.text = "DEATHS %d" % RunStats.deaths
	var was_freeze_active := freeze_active
	var requested := Input.is_action_pressed("freeze_time") and freeze_remaining > 0.0
	if requested and not was_freeze_active:
		_play_sfx("time_slow")
	elif was_freeze_active and not requested:
		_play_sfx("time_resume")
	freeze_active = requested
	player.set("time_slowed", requested and level_number == 3)
	# Keep the protagonist monochrome white; the HUD and environment show the freeze state.
	player.modulate = Color.WHITE
	for movable in get_tree().get_nodes_in_group("movable"):
		movable.set("frozen_by_player", requested and level_number != 3)
		movable.set("slowed_by_player", requested and level_number == 3)
		movable.set("modulate", Color("8a2be2") if requested and level_number == 3 else Color("00ff33") if requested else Color.WHITE)
	if level_number == 5 or level_number == 7 or level_number == 8 or level_number == 9 or level_number == 10:
		if level_number == 10:
			if player.global_position.y < 370.0:
				final_rail_b_unlocked = true
			var lower_rails_parked := relay_sliders[0].global_position.distance_to(relay_targets[0]) <= 24.0 and relay_sliders[1].global_position.distance_to(relay_targets[1]) <= 24.0
			if final_rail_b_unlocked and lower_rails_parked:
				final_rail_c_unlocked = true
			relay_sliders[1].set("drag_locked", not final_rail_b_unlocked)
			relay_sliders[2].set("drag_locked", not final_rail_c_unlocked)
		for index in range(relay_sliders.size()):
			var docked := relay_sliders[index].global_position.distance_to(relay_targets[index]) <= 24.0
			if level_number == 10 and bool(relay_sliders[index].get("drag_locked")):
				relay_sliders[index].modulate = Color("8a2be2")
			else:
				relay_sliders[index].modulate = Color("00ff33") if docked else Color("ff0033")
	if freeze_active:
		freeze_remaining = maxf(0.0, freeze_remaining - delta)
	elif not Input.is_action_pressed("freeze_time"):
		freeze_remaining = minf(3.0, freeze_remaining + delta * 0.55)
	energy_bar.value = freeze_remaining
	energy_bar.modulate = Color("8a2be2") if level_number == 3 else Color("00ff33") if freeze_remaining > 0.5 else Color("ff0033")
	_check_switch()
	if exit_open:
		status_label.text = "PLATE ACTIVE - EXIT OPEN!\nReach the green gate.  Q resets gravity."
	elif level_number == 4 and relay_bar_a != null and relay_bar_b != null:
		status_label.text = "A/D move  SPACE jump  Q flip  E/R push-pull  F freeze\nLEFT-DRAG bars sideways on their rails (no gravity)\nAlign A left + B right, then drag box to yellow plate."
	elif level_number == 5 and not relay_sliders.is_empty():
		status_label.text = "CROSSROUTER: drag each relay along its rail\nUse the neon-green junction network; parked relays light green.\nThen move the green box onto the yellow plate."
	elif level_number == 6:
		status_label.text = "PORTALS move you and the green box across the wall.\nDrag the box into the green portal; walk through too.\nMove the box onto the yellow plate to exit."
	elif level_number == 7:
		status_label.text = "Maze route: portal 1 -> lower passage -> portal 2\nPark rail A left and rail B right; both become green.\nThen place the box on the bottom-right plate."
	elif level_number == 8:
		status_label.text = "SYSTEMS MAZE: park rails A and B first.\nRoute the box through three portal pairs; lift C to clear the last lane.\nMove it onto the final plate."
	elif level_number == 9:
		status_label.text = "START CENTER: slide A left and B right to clear both tunnels.\nPush green through the left tunnel; guide red through the right.\nGREEN -> LEFT DOCK   |   RED -> RIGHT DOCK"
	elif level_number == 10:
		if not final_rail_b_unlocked:
			status_label.text = "FINAL ASCENT: drag rail A left to its green dock, then rise through the first wide gap with Q.\nReach the middle tier to unlock rail B. The boxes fit through the same opening."
		elif not final_rail_c_unlocked:
			status_label.text = "MIDDLE TIER: park rail B at the right dock.\nOnce A and B are both green, rail C unlocks at the upper shelf.\nUse Q and mouse-drag to guide both boxes upward."
		else:
			status_label.text = "UPPER TIER: move rail C to the right dock to clear the 180 px opening.\nThere is room to steer both boxes between the shelves and ceiling.\nGREEN -> LEFT summit plate   |   RED -> RIGHT summit plate"

func _add_platform(center: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	var visual := TextureRect.new()
	visual.position = -size * 0.5
	visual.size = size
	visual.texture = preload("res://assets/environment/platform_tile_64.png")
	visual.modulate = color
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_TILE
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)
	add_child(body)

func _add_background() -> void:
	var background := TextureRect.new()
	background.name = "WatchingTreeBackground"
	background.texture = preload("res://assets/environment/lab_background.png")
	background.position = Vector2.ZERO
	background.size = Vector2(1100, 588)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -100
	add_child(background)

func _build_crt_overlay() -> void:
	var crt_layer := CanvasLayer.new()
	crt_layer.name = "CRTRenderPass"
	crt_layer.layer = 100
	add_child(crt_layer)
	var overlay := ColorRect.new()
	overlay.name = "ScanlineDitherOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = CRT_SHADER
	overlay.material = material
	crt_layer.add_child(overlay)

func _make_rect(center: Vector2, size: Vector2, color: Color) -> ColorRect:
	var visual := ColorRect.new()
	visual.position = center - size * 0.5
	visual.size = size
	visual.color = color
	add_child(visual)
	return visual

func _add_relay_dock(center: Vector2, label_text: String) -> void:
	var rail := _make_rect(Vector2(615, center.y), Vector2(700, 6), Color("8a2be2"))
	rail.name = "RelayRail" + label_text
	var dock := _make_rect(center, Vector2(150, 34), Color("00ff33"))
	dock.name = "RelayDock" + label_text
	var mark := Label.new()
	mark.text = "PARK " + label_text
	mark.position = center + Vector2(-32, 20)
	mark.add_theme_color_override("font_color", Color("00ff33"))
	mark.add_theme_font_size_override("font_size", 14)
	add_child(mark)

func _add_route_rail(horizontal: bool, fixed_axis: float, start: float, finish: float, label_text: String, dock_axis: float) -> void:
	var rail_center := Vector2((start + finish) * 0.5, fixed_axis) if horizontal else Vector2(fixed_axis, (start + finish) * 0.5)
	var rail_size := Vector2(finish - start, 5) if horizontal else Vector2(5, finish - start)
	var rail := _make_rect(rail_center, rail_size, Color("8a2be2"))
	rail.name = "RouterRail" + label_text
	var dock_center := Vector2(dock_axis, fixed_axis) if horizontal else Vector2(fixed_axis, dock_axis)
	var dock_size := Vector2(48, 36) if horizontal else Vector2(36, 48)
	var dock := _make_rect(dock_center, dock_size, Color("00ff33"))
	dock.name = "RouterDock" + label_text
	var label := Label.new()
	label.text = "PARK " + label_text
	label.position = dock_center + Vector2(-30, 24)
	label.add_theme_color_override("font_color", Color("00ff33"))
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _add_portal_pair(first_position: Vector2, second_position: Vector2, exit_distance: float = 70.0) -> void:
	_add_portal(first_position, second_position, Vector2.RIGHT, Color("00ff33"), exit_distance)
	_add_portal(second_position, first_position, Vector2.LEFT, Color("8a2be2"), exit_distance)

func _add_portal(portal_position: Vector2, destination: Vector2, exit_direction: Vector2, portal_color: Color, exit_distance: float) -> void:
	var portal := Area2D.new()
	portal.name = "Portal_%d_%d" % [roundi(portal_position.x), roundi(portal_position.y)]
	portal.position = portal_position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42, 108)
	collision.shape = shape
	portal.add_child(collision)
	add_child(portal)
	portal.body_entered.connect(_on_portal_body_entered.bind(destination, exit_direction, exit_distance))
	_make_rect(portal_position, Vector2(24, 112), Color("000000"))
	_make_rect(portal_position, Vector2(13, 96), portal_color)
	var label := Label.new()
	label.text = "PORTAL"
	label.position = portal_position + Vector2(-29, 58)
	label.add_theme_color_override("font_color", portal_color)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

func _on_portal_body_entered(body: Node2D, destination: Vector2, exit_direction: Vector2, exit_distance: float) -> void:
	if body != player and body != pillar and body != second_pillar:
		return
	var cooldown_until := int(body.get_meta("portal_cooldown_until", 0))
	if Time.get_ticks_msec() < cooldown_until:
		return
	body.set_meta("portal_cooldown_until", Time.get_ticks_msec() + portal_cooldown_ms)
	body.global_position = destination + exit_direction * exit_distance
	_play_sfx("portal")
	if body is CharacterBody2D:
		var character_body := body as CharacterBody2D
		character_body.velocity = Vector2.ZERO

func _create_track_slider(object_name: String, start_position: Vector2, size: Vector2, horizontal: bool, minimum: float, maximum: float, fixed_axis: float) -> CharacterBody2D:
	var slider := _create_movable_pillar(object_name, start_position, size)
	slider.set("horizontal_track", horizontal)
	slider.set("vertical_track", not horizontal)
	if horizontal:
		slider.set("track_y", fixed_axis)
		slider.set("track_min_x", minimum)
		slider.set("track_max_x", maximum)
	else:
		slider.set("track_x", fixed_axis)
		slider.set("track_min_y", minimum)
		slider.set("track_max_y", maximum)
	# Rail beams collide with layer 1 (player and green box), but not each other.
	slider.collision_layer = 2
	slider.collision_mask = 0 if level_number == 10 else 1
	slider.set("drag_locked", false)
	var tag := Label.new()
	tag.text = object_name.right(1)
	tag.position = Vector2(-6, -12)
	tag.add_theme_color_override("font_color", Color("000000"))
	tag.add_theme_font_size_override("font_size", 14)
	slider.add_child(tag)
	return slider

func _create_movable_pillar(object_name: String, start_position: Vector2, object_size: Vector2 = Vector2(54, 82)) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.name = object_name
	body.set_script(PillarScript)
	body.set("body_size", object_size)
	body.z_index = 5
	body.position = start_position
	add_child(body)
	return body

func _add_spike_hazard(center: Vector2, size: Vector2, hazard_name: String) -> void:
	var hazard := Area2D.new()
	hazard.name = hazard_name
	hazard.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	hazard.add_child(collision)
	add_child(hazard)
	var visual := ColorRect.new()
	visual.position = center - size * 0.5
	visual.size = size
	visual.color = Color("ff0033")
	add_child(visual)
	# Acid-yellow teeth make each red hazard read as a living maw at a glance.
	var tooth_count := maxi(2, floori(size.x / 18.0))
	for tooth_index in range(tooth_count):
		var tooth := Polygon2D.new()
		var tooth_width := size.x / float(tooth_count)
		var left := -size.x * 0.5 + tooth_width * tooth_index
		tooth.polygon = PackedVector2Array([
			Vector2(left, -size.y * 0.5),
			Vector2(left + tooth_width, -size.y * 0.5),
			Vector2(left + tooth_width * 0.5, -size.y * 0.5 + minf(10.0, size.y * 0.45))
		])
		tooth.position = center
		tooth.color = Color("ffff00")
		tooth.z_index = 1
		add_child(tooth)
	hazard.body_entered.connect(_on_spike_body_entered)

func _check_switch(_body: Node2D = null) -> void:
	if not has_meta("switch_area"):
		return
	var area: Area2D = get_meta("switch_area")
	var pressed := false
	if level_number == 9 or level_number == 10:
		var second_area: Area2D = get_meta("second_switch_area")
		var silver_on_plate := _area_contains_body(area, pillar)
		var amber_on_plate := _area_contains_body(second_area, second_pillar)
		var first_plate: ColorRect = get_meta("switch_visual")
		var second_plate: ColorRect = get_meta("second_switch_visual")
		var silver_plate_idle := Color("00ff33") if level_number == 10 else Color("ffff00")
		first_plate.color = Color("00ff33") if silver_on_plate else silver_plate_idle
		second_plate.color = Color("00ff33") if amber_on_plate else Color("8a2be2")
		pressed = silver_on_plate and amber_on_plate
	else:
		pressed = _area_contains_body(area, pillar)
	if level_number == 4:
		var bars_parked := relay_bar_a != null and relay_bar_b != null and absf(relay_bar_a.global_position.x - 300.0) < 24.0 and absf(relay_bar_b.global_position.x - 930.0) < 24.0
		pressed = pressed and bars_parked
	elif level_number == 5 or level_number == 7 or level_number == 8 or level_number == 9 or level_number == 10:
		var all_relays_parked := relay_sliders.size() == relay_targets.size()
		for index in range(relay_sliders.size()):
			if relay_sliders[index].global_position.distance_to(relay_targets[index]) > 24.0:
				all_relays_parked = false
		pressed = pressed and all_relays_parked
	if pressed != switch_pressed:
		switch_pressed = pressed
		exit_open = pressed
		exit_door_visual.color = Color("ff0033")
		exit_door_visual.visible = not pressed
		exit_door_shape.set_deferred("disabled", pressed)
		exit_portal.visible = pressed
		var plate: ColorRect = get_meta("switch_visual")
		var idle_plate_color := Color("00ff33") if level_number == 10 else Color("ffff00")
		plate.color = Color("00ff33") if pressed else idle_plate_color
		if level_number == 9 or level_number == 10:
			var second_plate: ColorRect = get_meta("second_switch_visual")
			second_plate.color = Color("00ff33") if pressed else Color("8a2be2")
		if pressed:
			status_label.text = "PLATE ACTIVE - EXIT OPEN!\nReach the green gate.  Q resets gravity."
			_play_sfx("switch")

func _area_contains_body(area: Area2D, target_body: Node2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body == target_body:
			return true
	return false

func _on_exit_body_entered(body: Node2D) -> void:
	if body == player and exit_open and not completed:
		completed = true
		var run_result := RunStats.finish_level()
		if level_number == 10:
			victory_title_label.text = "YOU WAKE UP"
			victory_title_label.add_theme_color_override("font_color", Color("ffff00"))
			victory_result_label.text = "The facility dissolves into static. You wake in your room at sunrise, heart pounding.\n\nFor a moment, the nightmare is over. Then your dark screen flickers: TEST 11 READY."
		else:
			victory_result_label.text += "\n\nTIME %s  |  LEVEL %04d  |  TOTAL %04d" % [
			RunStats.formatted_time(),
			int(run_result["level_score"]),
			int(run_result["total_score"]),
			]
		if level_number == 10:
			victory_result_label.text += "\n\nRUN COMPLETE  |  TIME %s  |  SCORE %04d" % [RunStats.formatted_time(), int(run_result["total_score"])]
			victory_result_label.text += "\n\nPRESS ENTER TO RETURN TO MENU"
		_play_sfx("win_wacky")
		player.set_physics_process(false)
		victory_overlay.visible = true

func _on_gravity_changed(inverted: bool) -> void:
	_play_sfx("gravity_flip")
	gravity_label.text = "GRAVITY  UP" if inverted else "GRAVITY  DOWN"
	gravity_label.add_theme_color_override("font_color", Color("8a2be2") if inverted else Color("00ff33"))

func _on_player_jumped() -> void:
	_play_sfx("jump")

func _on_player_object_manipulated() -> void:
	_play_sfx("object_move")

func _on_player_drag_started() -> void:
	_play_sfx("object_move")

func _on_player_died() -> void:
	if death_in_progress or completed:
		return
	death_in_progress = true
	RunStats.record_death()
	deaths_label.text = "DEATHS %d" % RunStats.deaths
	_play_sfx("death_fahhh")
	status_label.text = "SIGNAL LOST - reloading test room..."
	player.set_physics_process(false)
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()

func _on_reset_level_pressed() -> void:
	RunStats.record_restart()
	get_tree().reload_current_scene()

func _on_spike_body_entered(body: Node2D) -> void:
	if body == player:
		_on_player_died()
