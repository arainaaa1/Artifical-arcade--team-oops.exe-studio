extends Control

const LEVEL_SCENES: Array[String] = [
	"res://test_room.tscn",
	"res://level_2.tscn",
	"res://level_3.tscn",
	"res://level_4.tscn",
	"res://level_5.tscn",
	"res://level_6.tscn",
	"res://level_7.tscn",
	"res://level_8.tscn",
	"res://level_9.tscn",
	"res://level_10.tscn",
]

const LEVEL_NAMES: Array[String] = [
	"BROKEN FLOOR", "CRUSHING CORRIDOR", "INVERTED LAB", "HORIZONTAL RELAY",
	"CROSSROUTER", "PORTAL TEST", "TELEPORT MAZE", "SYSTEMS MAZE",
	"DUAL-CIRCUIT", "FINAL ASCENT",
]

var main_screen: CenterContainer
var levels_screen: CenterContainer
var controls_screen: CenterContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	main_screen = _make_screen()
	levels_screen = _make_screen()
	controls_screen = _make_screen()
	_build_main_menu()
	_build_level_menu()
	_build_controls_menu()
	_show_screen(main_screen)


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "FloatingEyesOnBlack"
	background.texture = preload("res://assets/environment/title_eye_background.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _make_screen() -> CenterContainer:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(holder)
	return holder


func _make_panel(holder: CenterContainer, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.88)
	panel_style.border_color = Color("8a2be2")
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", panel_style)
	holder.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column


func _add_heading(column: VBoxContainer, subtitle_text: String) -> void:
	var title := Label.new()
	title.text = "GLITCH//FALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("ffffff"))
	title.add_theme_color_override("font_outline_color", Color("8a2be2"))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("ffff00"))
	subtitle.add_theme_font_size_override("font_size", 14)
	column.add_child(subtitle)


func _build_main_menu() -> void:
	var column := _make_panel(main_screen, 420)
	_add_heading(column, "THE FACILITY IS WATCHING")
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 7
	column.add_child(spacer)
	column.add_child(_make_button("PLAY", _on_play_pressed, Color("00ff33")))
	column.add_child(_make_button("LEVEL SELECT", _on_levels_pressed, Color("8a2be2")))
	column.add_child(_make_button("CONTROLS", _on_controls_pressed, Color("ff0033")))
	column.add_child(_make_button("QUIT", _on_quit_pressed, Color("ffff00")))


func _build_level_menu() -> void:
	var column := _make_panel(levels_screen, 620)
	_add_heading(column, "CHOOSE A FACILITY SECTOR")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 9)
	column.add_child(grid)
	for index in range(LEVEL_SCENES.size()):
		var label := "%02d  %s" % [index + 1, LEVEL_NAMES[index]]
		var button := _make_button(label, _load_level.bind(index), Color("8a2be2"))
		button.custom_minimum_size = Vector2(270, 42)
		button.add_theme_font_size_override("font_size", 12)
		grid.add_child(button)
	column.add_child(_make_button("BACK", _on_back_pressed, Color("ff0033")))


func _build_controls_menu() -> void:
	var column := _make_panel(controls_screen, 560)
	_add_heading(column, "FACILITY CONTROL GUIDE")
	var instructions := Label.new()
	instructions.text = "A / D or LEFT / RIGHT     MOVE\nSPACE     JUMP\nQ     REVERSE GRAVITY\nE / R     PULL OR PUSH OBJECTS\nHOLD F     FREEZE ELIGIBLE OBJECTS\nLEFT CLICK + DRAG     MOVE BOXES OR RAILS\nWALK INTO A PORTAL     TELEPORT THROUGH IT"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	instructions.add_theme_color_override("font_color", Color("ffffff"))
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size = Vector2(0, 205)
	column.add_child(instructions)
	column.add_child(_make_button("BACK", _on_back_pressed, Color("ff0033")))


func _make_button(label: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(340, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("ffff00"))
	button.add_theme_color_override("font_hover_color", Color("00ff33"))
	button.add_theme_color_override("font_pressed_color", Color("000000"))
	button.add_theme_color_override("font_focus_color", Color("ffffff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.0, 0.0, 0.0, 0.96)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.04, 0.04, 0.04, 1.0)
	hover.border_color = Color("00ff33")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("ff0033")
	pressed.border_color = Color("ffff00")
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color("ffff00")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	return button


func _show_screen(active: CenterContainer) -> void:
	main_screen.visible = active == main_screen
	levels_screen.visible = active == levels_screen
	controls_screen.visible = active == controls_screen


func _on_play_pressed() -> void:
	_load_level(0)


func _on_levels_pressed() -> void:
	_show_screen(levels_screen)


func _on_controls_pressed() -> void:
	_show_screen(controls_screen)


func _on_back_pressed() -> void:
	_show_screen(main_screen)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _load_level(index: int) -> void:
	RunStats.start_run()
	get_tree().change_scene_to_file(LEVEL_SCENES[index])


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if levels_screen.visible or controls_screen.visible:
			_show_screen(main_screen)
