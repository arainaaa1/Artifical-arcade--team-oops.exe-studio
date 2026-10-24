extends CharacterBody2D

const FALL_ACCEL := 1000.0
const MAX_FALL := 750.0
const SILVER_BOX_TEXTURE: Texture2D = preload("res://assets/sprites/box_silver_64.png")
const AMBER_BOX_TEXTURE: Texture2D = preload("res://assets/sprites/box_amber_64.png")
const CONCRETE_TEXTURE: Texture2D = preload("res://assets/sprites/pillar_concrete_64.png")
const RAIL_TEXTURE: Texture2D = preload("res://assets/environment/rail_tile_64.png")
@export var body_size := Vector2(54, 82)
@export var drag_locked := false
@export var horizontal_track := false
@export var vertical_track := false
@export var track_y := 0.0
@export var track_min_x := 0.0
@export var track_max_x := 1100.0
@export var track_x := 0.0
@export var track_min_y := 0.0
@export var track_max_y := 588.0
var gravity_sign := 1.0
var frozen_by_player := false
var slowed_by_player := false
var dragging := false
var drag_target := Vector2.ZERO
var gravity_clock := 0.0

func _ready() -> void:
	add_to_group("movable")
	var shape := RectangleShape2D.new()
	shape.size = body_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var is_rail := name.begins_with("Router") or name.begins_with("FinalRail") or name.begins_with("MazeRail") or name.begins_with("DualRail") or name.begins_with("HorizontalPillar")
	if is_rail:
		var art := Sprite2D.new()
		art.name = "PillarBody"
		art.texture = RAIL_TEXTURE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.scale = body_size / Vector2(64.0, 64.0)
		add_child(art)
	else:
		var art := Sprite2D.new()
		art.name = "PillarBody"
		if name == "SilverBox":
			art.texture = SILVER_BOX_TEXTURE
		elif name == "AmberBox":
			art.texture = AMBER_BOX_TEXTURE
		else:
			art.texture = CONCRETE_TEXTURE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.scale = body_size / Vector2(64.0, 64.0)
		add_child(art)

func _physics_process(delta: float) -> void:
	if horizontal_track:
		# Relay bars are sliders on a fixed rail: gravity never changes their lane.
		global_position.y = track_y
		if dragging:
			var target_x := clampf(drag_target.x, track_min_x, track_max_x)
			velocity = Vector2(clampf((target_x - global_position.x) * 12.0, -900.0, 900.0), 0.0)
			move_and_slide()
			global_position.y = track_y
			return
		velocity = Vector2.ZERO
		return
	if vertical_track:
		# Cross-router sliders use the same mouse control on a vertical rail.
		global_position.x = track_x
		if dragging:
			var target_y := clampf(drag_target.y, track_min_y, track_max_y)
			velocity = Vector2(0.0, clampf((target_y - global_position.y) * 12.0, -900.0, 900.0))
			move_and_slide()
			global_position.x = track_x
			return
		velocity = Vector2.ZERO
		return
	gravity_clock += delta
	if gravity_clock >= 0.08:
		gravity_clock = 0.0
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			gravity_sign = player.gravity_sign
	if dragging:
		var offset := drag_target - global_position
		var drag_speed := 700.0 * (0.18 if slowed_by_player else 1.0)
		velocity = offset.limit_length(drag_speed)
		move_and_slide()
		return
	if frozen_by_player:
		velocity = Vector2.ZERO
		return
	var physics_delta := delta * (0.18 if slowed_by_player else 1.0)
	velocity.y = move_toward(velocity.y, MAX_FALL * gravity_sign, FALL_ACCEL * physics_delta)
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * physics_delta)
	if slowed_by_player:
		velocity *= 0.18
	move_and_slide()
	if slowed_by_player:
		velocity /= 0.18

func apply_impulse_from_player(player_position: Vector2, direction: float) -> void:
	if frozen_by_player:
		return
	var delta_x := global_position.x - player_position.x
	if absf(delta_x) > 100.0:
		return
	velocity.x = direction * 420.0
	if is_on_floor() or is_on_ceiling():
		velocity.y = -gravity_sign * 100.0

func begin_drag(mouse_position: Vector2) -> void:
	if drag_locked:
		return
	dragging = true
	drag_target = mouse_position

func set_drag_target(mouse_position: Vector2) -> void:
	drag_target = mouse_position

func end_drag() -> void:
	dragging = false
	velocity = Vector2.ZERO

