extends CharacterBody2D

signal gravity_changed(inverted: bool)
signal died
signal jumped
signal object_manipulated
signal object_drag_started

const MOVE_SPEED := 265.0
const JUMP_SPEED := 470.0
const GRAVITY := 1200.0
const REACH := 102.0
const DRAG_DURATION := 2.5
const PLAYER_SHEET: Texture2D = preload("res://assets/sprites/player_sheet_64.png")
@export var death_y_top := -80.0
@export var death_y_bottom := 720.0
var gravity_sign := 1.0
var facing := 1.0
var flip_ready := true
var time_slowed := false
var target: CharacterBody2D
var drag_target: CharacterBody2D
var drag_remaining := 0.0
var body_shape: CollisionShape2D
var visual: AnimatedSprite2D
var target_ring: Line2D

func _ready() -> void:
	add_to_group("player")
	var shape := CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 42.0
	body_shape = CollisionShape2D.new()
	body_shape.shape = shape
	add_child(body_shape)
	visual = AnimatedSprite2D.new()
	visual.sprite_frames = _build_player_animations()
	visual.animation = "default"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.play("default")
	add_child(visual)
	target_ring = Line2D.new()
	target_ring.points = PackedVector2Array([Vector2(-24, -24), Vector2(24, -24), Vector2(24, 24), Vector2(-24, 24), Vector2(-24, -24)])
	target_ring.width = 2.0
	target_ring.default_color = Color("ffff00")
	target_ring.visible = false
	add_child(target_ring)

func _physics_process(delta: float) -> void:
	if drag_target != null and is_instance_valid(drag_target) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		drag_remaining -= delta
		if drag_remaining > 0.0:
			drag_target.call("set_drag_target", get_global_mouse_position())
		else:
			drag_target.call("end_drag")
			drag_target = null
	else:
		drag_target = null
	var time_scale := 0.55 if time_slowed else 1.0
	if Input.is_action_just_pressed("gravity_flip") and flip_ready:
		gravity_sign *= -1.0
		up_direction = Vector2.UP * gravity_sign
		velocity.y = 0.0
		visual.scale.y = gravity_sign
		flip_ready = false
		gravity_changed.emit(gravity_sign < 0)
	if not Input.is_action_pressed("gravity_flip"):
		flip_ready = true

	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
	visual.flip_h = facing < 0.0
	velocity.x = move_toward(velocity.x, axis * MOVE_SPEED, 1500.0 * delta)
	velocity.y += GRAVITY * gravity_sign * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -JUMP_SPEED * gravity_sign
		jumped.emit()
	if time_slowed:
		velocity *= time_scale
	move_and_slide()
	if time_slowed:
		velocity /= time_scale
	_update_animation()
	if global_position.y < death_y_top or global_position.y > death_y_bottom:
		died.emit()
	_update_target()
	if target != null:
		var away_from_player := signf(target.global_position.x - global_position.x)
		if Input.is_action_just_pressed("pull_object"):
			target.call("apply_impulse_from_player", global_position, -away_from_player)
			object_manipulated.emit()
		if Input.is_action_just_pressed("push_object"):
			target.call("apply_impulse_from_player", global_position, away_from_player)
			object_manipulated.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_position := get_global_mouse_position()
			var clicked_object: CharacterBody2D
			var closest: float = INF
			for candidate in get_tree().get_nodes_in_group("movable"):
				if candidate is CharacterBody2D and candidate.has_method("begin_drag") and not bool(candidate.get("drag_locked")):
					var size: Vector2 = candidate.get("body_size")
					# A generous hit area makes the long horizontal relay bars easy to grab.
					var half_size := size * 0.5 + Vector2(32, 32)
					var offset: Vector2 = (candidate.global_position - mouse_position).abs()
					var distance: float = candidate.global_position.distance_to(mouse_position)
					if offset.x <= half_size.x and offset.y <= half_size.y and distance < closest:
						clicked_object = candidate
						closest = distance
			if clicked_object != null:
				drag_target = clicked_object
				drag_remaining = DRAG_DURATION
				drag_target.call("begin_drag", mouse_position)
				object_drag_started.emit()
		else:
			if drag_target != null and is_instance_valid(drag_target):
				drag_target.call("end_drag")
			drag_target = null

func _update_target() -> void:
	target = null
	var nearest_distance := REACH
	for candidate in get_tree().get_nodes_in_group("movable"):
		if candidate is CharacterBody2D:
			var distance: float = global_position.distance_to(candidate.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				target = candidate
	target_ring.visible = target != null

func _build_player_animations() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	_add_animation_frames(frames, "default", 0, 4, 5.0)
	_add_animation_frames(frames, "walk", 1, 6, 10.0)
	_add_animation_frames(frames, "jump", 2, 2, 6.0)
	return frames

func _add_animation_frames(frames: SpriteFrames, animation_name: StringName, row: int, frame_count: int, speed: float) -> void:
	if animation_name != "default":
		frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop_mode(animation_name, SpriteFrames.LOOP_LINEAR)
	for column in range(frame_count):
		var frame := AtlasTexture.new()
		frame.atlas = PLAYER_SHEET
		frame.region = Rect2(column * 64, row * 64, 64, 64)
		frame.filter_clip = true
		frames.add_frame(animation_name, frame)

func _update_animation() -> void:
	var next_animation := "jump" if not is_on_floor() else "walk" if absf(velocity.x) > 12.0 else "default"
	if visual.animation != next_animation:
		visual.play(next_animation)
