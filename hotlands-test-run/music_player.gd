extends Node

const MUSIC_PATH := "res://assets/audio/The_Midnight_Tower_Toll.mp3"
const MUSIC_VOLUME_DB := -18.0

var music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var music_stream := load(MUSIC_PATH) as AudioStreamMP3
	if music_stream == null:
		push_warning("Background music could not be loaded: " + MUSIC_PATH)
		return

	music_stream.loop = true
	if DisplayServer.get_name() == "headless":
		return

	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.stream = music_stream
	music_player.volume_db = MUSIC_VOLUME_DB
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	music_player.play()


func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
